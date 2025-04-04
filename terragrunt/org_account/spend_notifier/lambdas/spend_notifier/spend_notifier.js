const { CostExplorerClient, GetCostAndUsageCommand } = require("@aws-sdk/client-cost-explorer");
const costExplorerClient = new CostExplorerClient({ region: "us-east-1" });

const { OrganizationsClient, ListAccountsCommand, ListTagsForResourceCommand } = require("@aws-sdk/client-organizations");
const orgClient = new OrganizationsClient({ region: "us-east-1" });

const https = require('https')

exports.handler = async (event) => {
  const hook = event.hook;
  const today = new Date();

  // call the daily cost function to get daily costs
  const [dailyAccountCost, amountIncrease] = await getDailyAccountCost()

  const accountCost = await getAccountCost()
  let accounts = await getAccounts()

  // get all scratch accounts that exceeded the threshold of $500 yesterday
  const scratchAccountsExceedingThreshold = await getScratchAccountsExceedingThreshold()

  let accountIncreases = {}
  let scratchAccountsAffected = {}

  Object.keys(accounts).forEach(key => {
    if(accountCost.hasOwnProperty(key)){
      accounts[key]["Cost"] = accountCost[key]
      // determine if the account is a scratch account
      accounts[key]["Name"].toLowerCase().includes("scratch") ? accounts[key]["isScratch"] = true : accounts[key]["isScratch"] = false 
    } else {
      accounts[key]["Cost"] = 0
    }

    // if the account is not a scratch account and there is a 35% increase in costs for yesterday vs day before AND the difference in the dollar amount is greater than $10, add to accountIncreases
    if(dailyAccountCost.hasOwnProperty(key) && dailyAccountCost[key] >35 && !accounts[key]["isScratch"] && amountIncrease.hasOwnProperty(key) && amountIncrease[key] > 10) {
          accountIncreases[accounts[key]["Name"]] = dailyAccountCost[key]
    }

    // if the account is a scratch account and it exceeded the threshold of $500 yesterday, add to scratchAccountsAffected
    if (scratchAccountsExceedingThreshold.hasOwnProperty(key) && accounts[key]["isScratch"]) {
      scratchAccountsAffected[accounts[key]["Name"]] = scratchAccountsExceedingThreshold[key]
    }
  });

  let BU = {}

  Object.values(accounts).forEach(account => {
    if (BU.hasOwnProperty(account["BU"])) {
      BU[account["BU"]] = BU[account["BU"]] + account["Cost"]
    } else {
      BU[account["BU"]] = account["Cost"]
    }
  })
  const totalCost = Object.values(BU).reduce((a, b) => a + b, 0)

  // get the amounts for the total cost from April 1 last year (essentially for the current fiscal year)
  const totalCostFromApril1 = await getTotalCostFromApril1()
  const totalCostFromApril1Formatted = `$${totalCostFromApril1.toFixed(2).replace(/\d(?=(\d{3})+\.)/g, '$&,')} USD`

  const header = {
          "type": "header",
          "text": {
            "type": "plain_text",
            "text": `Current AWS spend for ${(today.getMonth() + 1).pad(2)}-${today.getFullYear()}`,
            "emoji": true
          }
        }

  const footer = {
          "type": "section",
          "fields": [
            { "type": "mrkdwn", "text": `*Total*` },
            { "type": "mrkdwn", "text": `$${totalCost.toFixed(2).replace(/\d(?=(\d{3})+\.)/g, '$&,')} USD` },
            { "type": "mrkdwn", "text": `*Total for this FY until ${(today.getMonth() + 1).pad(2)}-${today.getDate().pad(2)}*` },
            { "type": "mrkdwn", "text": `${totalCostFromApril1Formatted}` }
          ]
        }
    
  const blocks = Object.entries(BU).map(bu =>(
    {
        "type": "section",
        "fields": [{ "type": "mrkdwn", "text": `*${bu[0]}*` }, { "type": "mrkdwn", "text": `$${bu[1].toFixed(2).replace(/\d(?=(\d{3})+\.)/g, '$&,')} USD` }]
    }
    )).flat()

  // concatenate accounts that have increases and construct a new blocks section 
  const costIncreasedAccounts= Object.keys(accountIncreases).join(', ').toString()
  const costIncreasedAccountsSection= {
        "type": "section",
        "text": 
          { "type": "mrkdwn", "text": `Account(s) *${costIncreasedAccounts}* saw at least *35% increase in cost* yesterday from previous day cost calculations.` },
    }

  // concatenate accounts that exceeded the threshold of $500 and construct a new blocks section
  const scratchAccounts= Object.keys(scratchAccountsAffected).join(', ').toString()
  const scratchAccountsSection= {
        "type": "section",
        "text":
          { "type": "mrkdwn", "text": `Account(s) *${scratchAccounts} exceeded* the threshold of *$500* yesterday.` },
  }

 

  blocks.splice(0,0, header)
  blocks.push({ "type": "divider"})
  blocks.push(footer)

  // if there are accounts that have 35% increase in cost, add the section to the message
  if (costIncreasedAccounts.length > 0) {
    blocks.push(costIncreasedAccountsSection);
  }

  // if the scratch accounts exceeded the threshold of $500, add the section to the message
  if (scratchAccounts.length > 0) {
    blocks.push(scratchAccountsSection);
  }


  const data = JSON.stringify(
    {
      "blocks": blocks
    }
  )

  const options = {
    hostname: 'sre-bot.cdssandbox.xyz',
    port: 443,
    path: `/hook/${hook}`,
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Content-Length': data.length,
      'User-Agent':'AWS_Lambda_Cost_Notifier_Function (Node.js)'  // Set User-Agent header
    }
  }

  const resp = await doRequest(options, data);
  console.log(resp)

  const response = {
    statusCode: 200,
    body: JSON.stringify({ success: true }),
  };
  return response;
};

async function getAccounts() {
  let accounts = [];
  let response = {};
  let params = {};

  response = await orgClient.send(new ListAccountsCommand(params));
  accounts = [...accounts, ...response.Accounts];

  while (response.NextToken) {
    params.NextToken = response.NextToken;
    response = await orgClient.send(new ListAccountsCommand(params));
    accounts = [...accounts, ...response.Accounts];
  }
  let results = {}
  for (let i = 0; i < accounts.length; i++) {
    let account = accounts[i];
    let tags = await orgClient.send(new ListTagsForResourceCommand({ ResourceId: account["Id"] }));

    results[account["Id"]] = { Name: account["Name"], BU: getEnvTag(tags)  }
  }
  return results
}

function getEnvTag(tags) {
  if (tags.Tags.length === 0) {
    return "Not tagged"
  }
  return tags.Tags.find(tag => tag["Key"] == "business_unit").Value
}

async function getAccountCost() {
  const today = new Date();
  const firstDayOfMonth = new Date(today.getFullYear(), today.getMonth(), 1).toISOString().split("T")[0];
  const lastDayOfMonth = new Date(today.getFullYear(), today.getMonth() + 1, 0).toISOString().split("T")[0];

  const params = {
    Granularity: "MONTHLY",
    TimePeriod: { Start: firstDayOfMonth, End: lastDayOfMonth },
    Metrics: ["UNBLENDED_COST"],
    GroupBy: [
      {
        Type: "DIMENSION",
        Key: "LINKED_ACCOUNT"
      }]
  };

  const result = await costExplorerClient.send(new GetCostAndUsageCommand(params));
  return result["ResultsByTime"][0]["Groups"].reduce((acc, curr) => {
    acc[curr["Keys"][0]] = parseFloat(curr["Metrics"]["UnblendedCost"]["Amount"]);
    return acc;
  }, {});
}

/**
 * Calculates the total cost from April 1 of the current year until today.
 * @returns {number} The total cost from April 1 of the current year until today.
 * @throws {Error} If the Cost Explorer API call fails.
 * @example
 * const totalCost = await getTotalCostFromApril1();
 * console.log(totalCost);
 * // 1234.56
 */
async function getTotalCostFromApril1() {
  // Get today's date and format as YYYY-MM-DD.
  const today = new Date();
  const todayDate = today.toISOString().split("T")[0];

  // Define April 1 of the current year (month index 3 = April)
  const year = today.getMonth() >= 3 ? today.getFullYear() : today.getFullYear() - 1;
  const april1 = new Date(year, 3, 1).toISOString().split("T")[0];

  // Set up Cost Explorer parameters:
  const params = {
    Granularity: "MONTHLY",
    TimePeriod: { Start: april1, End: todayDate },
    Metrics: ["UNBLENDED_COST"],
    GroupBy: [
      {
        Type: "DIMENSION",
        Key: "LINKED_ACCOUNT",
      },
    ],
  };

// Call the Cost Explorer API
const result = await costExplorerClient.send(new GetCostAndUsageCommand(params));

// Sum up costs across all returned time periods (months)
const totalCost = result["ResultsByTime"].reduce((acc, period) => {
  const periodCost = period["Groups"].reduce((subAcc, group) => {
    return subAcc + parseFloat(group["Metrics"]["UnblendedCost"]["Amount"]);
  }, 0);
  return acc + periodCost;
}, 0);

return totalCost;
}

/**
 * Calculates the monthly accumulated cost for yesterday and the day before yesterday, and returns the accounts that exceeded the threshold of $500 yesterday but not the day before yesterday.
 * @returns {Object} An object containing the accounts that exceeded the threshold of $500 yesterday but not the day before yesterday, along with their monthly accumulated cost.
 */
async function getScratchAccountsExceedingThreshold() {
  const today = new Date();
  const todayDate = today.toISOString().split("T")[0];
  const firstDayOfMonth = new Date(today.getFullYear(), today.getMonth(), 1).toISOString().split("T")[0];
  const yesterday = new Date(today.setDate(today.getDate() - 1)).toISOString().split("T")[0];

  // do this calculation only if yesterday is greater than or equal to the first day of the month. This is needed since we go back 2 days to calculate the difference in cost.
  if (yesterday > firstDayOfMonth) {
    // construct params for cost explorer
    const paramsYesterday = {
      Granularity: "MONTHLY",
      TimePeriod: { Start: firstDayOfMonth, End: todayDate},
      Metrics: ["UNBLENDED_COST"],
      GroupBy: [
        {
        Type: "DIMENSION",
        Key: "LINKED_ACCOUNT"
      }]
    };

    const paramsDayBeforeYesterday = {
      Granularity: "MONTHLY",
      TimePeriod: { Start: firstDayOfMonth, End: yesterday},
      Metrics: ["UNBLENDED_COST"],
      GroupBy: [
        {
          Type: "DIMENSION",
          Key: "LINKED_ACCOUNT"
        }]
    };

    // get the monthly accumulated cost for yesterday and the day before yesterday
    const getAccumulatedCostsYesterday = await costExplorerClient.send(new GetCostAndUsageCommand(paramsYesterday));
    const getAccumulatedCostsDayBeforeYesterday = await costExplorerClient.send(new GetCostAndUsageCommand(paramsDayBeforeYesterday));

    // calculate which accounts exceeded the threshold of $500 yesterday but not the day before yesterday
    const scratchAccountsAffected = getAccumulatedCostsYesterday["ResultsByTime"][0]["Groups"].reduce((acc, curr) => {
      const accountName = curr["Keys"][0];
      const yesterdayCost = parseFloat(curr["Metrics"]["UnblendedCost"]["Amount"]);
      const dayBeforeYesterdayCost = getAccumulatedCostsDayBeforeYesterday["ResultsByTime"][0]["Groups"].find(group => group["Keys"][0] === accountName);
      if (yesterdayCost > 500 && (!dayBeforeYesterdayCost || parseFloat(dayBeforeYesterdayCost["Metrics"]["UnblendedCost"]["Amount"]) < 500)) {
        acc[accountName] = yesterdayCost;
      }
      return acc;
    }, {});

  return scratchAccountsAffected;
}
return {}
}

/**
 * Calculates the daily account cost for yesterday and the day before yesterday, and returns the percentage increase.
 * @returns {Object} An object containing the percentage increase in cost for each linked account.
 */
async function getDailyAccountCost() {
  const today = new Date();
  const dayToday = today.toISOString().split("T")[0];
  const yesterday = new Date(new Date().setDate(today.getDate() - 1)).toISOString().split("T")[0];
  const dayBeforeYesterday = new Date(new Date().setDate(today.getDate() - 2)).toISOString().split("T")[0];
  
  // construct params for cost explorer
  const paramsYesterday = {
    Granularity: "DAILY",
    TimePeriod: { Start: yesterday, End: dayToday},
    Metrics: ["UNBLENDED_COST"],
    GroupBy: [
      {
        Type: "DIMENSION",
        Key: "LINKED_ACCOUNT"
      }]
  };

  const paramsDayBeforeYesterday = {
    Granularity: "DAILY",
    TimePeriod: { Start: dayBeforeYesterday, End: yesterday},
    Metrics: ["UNBLENDED_COST"],
    GroupBy: [
      {
        Type: "DIMENSION",
        Key: "LINKED_ACCOUNT"
      }]
  };

  // get cost for yesterday and the day before yesterday
  const getCostsYesterday = await costExplorerClient.send(new GetCostAndUsageCommand(paramsYesterday));
  const getCostsDayBeforeYesterday = await costExplorerClient.send(new GetCostAndUsageCommand(paramsDayBeforeYesterday));

  // get the the amounts from the object for yesterday and the day before yesterday
  const yesterdayCosts = getCostsYesterday["ResultsByTime"][0]["Groups"].reduce((acc, curr) => {
    acc[curr["Keys"][0]] = parseFloat(curr["Metrics"]["UnblendedCost"]["Amount"]);
    return acc;
  }, {});

  const dayBeforeYesterdayCosts = getCostsDayBeforeYesterday["ResultsByTime"][0]["Groups"].reduce((acc, curr) => {
    acc[curr["Keys"][0]] = parseFloat(curr["Metrics"]["UnblendedCost"]["Amount"]);
    return acc;
  }, {});

  //calculate the difference between yesterday and the day before yesterday
  const difference = Object.keys(yesterdayCosts).reduce((acc, curr) => {
    acc[curr] = yesterdayCosts[curr] - dayBeforeYesterdayCosts[curr];
    return acc;
  }, {});

  //calculate the percentage increase and return it 
  const percentageIncrease = Object.keys(difference).reduce((acc, curr) => {
    acc[curr] = ((difference[curr] / dayBeforeYesterdayCosts[curr]) * 100).toFixed(2);
    return acc;
  }, {});

  //return the percentage increase and the difference in dollar amount
  return [percentageIncrease, difference];
}

function doRequest(options, data) {
  return new Promise((resolve, reject) => {
    const req = https.request(options, (res) => {
      res.setEncoding('utf8');
      let responseBody = '';

      res.on('data', (chunk) => {
        responseBody += chunk;
      });

      res.on('end', () => {
        resolve(responseBody);
      });
    });

    req.on('error', (err) => {
      reject(err);
    });

    req.write(data)
    req.end();
  });
}

Number.prototype.pad = function (size) {
  var s = String(this);
  while (s.length < (size || 2)) { s = "0" + s; }
  return s;
}