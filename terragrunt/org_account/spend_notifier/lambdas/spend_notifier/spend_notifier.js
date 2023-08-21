const AWS = require('aws-sdk');
const costexplorer = new AWS.CostExplorer({ region: 'us-east-1' });
const organizations = new AWS.Organizations({ region: 'us-east-1' });

const https = require('https')

exports.handler = async (event) => {
  const hook = event.hook;
  const today = new Date();

  // call the daily cost function to get daily costs
  const dailyAccountCost = await getDailyAccountCost()

  const accountCost = await getAccountCost()
  let accounts = await getAccounts()
  let accountIncreases = {}
  Object.keys(accounts).forEach(key => {
    if(accountCost.hasOwnProperty(key)){
      accounts[key]["Cost"] = accountCost[key]
    } else {
      accounts[key]["Cost"] = 0
    }
    // if there is a 35% increase in costs for yesterady vs day before, add to accountIncreases
    if(dailyAccountCost.hasOwnProperty(key) && dailyAccountCost[key] > 35) {
          accountIncreases[accounts[key]["Name"]] = dailyAccountCost[key]
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
          "fields": [{ "type": "mrkdwn", "text": `*Total*` }, { "type": "mrkdwn", "text": `$${totalCost.toFixed(2).replace(/\d(?=(\d{3})+\.)/g, '$&,')} USD` }]
        }
    
  const blocks = Object.entries(BU).map(bu =>(
    {
        "type": "section",
        "fields": [{ "type": "mrkdwn", "text": `*${bu[0]}*` }, { "type": "mrkdwn", "text": `$${bu[1].toFixed(2).replace(/\d(?=(\d{3})+\.)/g, '$&,')} USD` }]
    }
    )).flat();

  // concatenate accounts that have increases and construct a new blocks section 
  const costIncreasedAccounts= Object.keys(accountIncreases).join(', ').toString()
  const costIncreasedAccountsSection= {
        "type": "section",
        "text": 
          { "type": "mrkdwn", "text": `Accounts *${costIncreasedAccounts}* saw at least *35% increase in cost* yesterday from previous day cost calculations.` },
    }

  blocks.splice(0,0, header)
  blocks.push({ "type": "divider"})
  blocks.push(footer)

  // if there are accounts that have 35% increase in cost, add the section to the message
  if (costIncreasedAccounts.length > 0) {
    blocks.push(costIncreasedAccountsSection);
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
      'Content-Length': data.length
    }
  }
  const resp = await doRequest(options, data);
  
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

  response = await organizations.listAccounts(params).promise()
  accounts = [...accounts, ...response.Accounts];

  while (response.NextToken) {
    params.NextToken = response.NextToken;
    response = await organizations.listAccounts(params).promise()
    accounts = [...accounts, ...response.Accounts];
  }
  let results = {}
  for (let i = 0; i < accounts.length; i++) {
    let account = accounts[i];
    let tags = await organizations.listTagsForResource({ ResourceId: account["Id"] }).promise()

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

  const result = await costexplorer.getCostAndUsage(params).promise();
  return result["ResultsByTime"][0]["Groups"].reduce((acc, curr) => {
    acc[curr["Keys"][0]] = parseFloat(curr["Metrics"]["UnblendedCost"]["Amount"]);
    return acc;
  }, {});
}

/**
 * Calculates the daily account cost for yesterday and the day before yesterday, and returns the percentage increase.
 * @returns {Object} An object containing the percentage increase in cost for each linked account.
 */
async function getDailyAccountCost() {
  const today = new Date();
  const yesterday = new Date(today.getFullYear(), today.getMonth(), today.getDate() - 1).toISOString().split("T")[0];
  const dayBeforeYesterday = new Date(today.getFullYear(), today.getMonth(), today.getDate() - 2).toISOString().split("T")[0];
  const twoDaysBeforeYesterday = new Date(today.getFullYear(), today.getMonth(), today.getDate() - 3).toISOString().split("T")[0];

  // construct params for cost explorer
  const paramsYesterday = {
    Granularity: "DAILY",
    TimePeriod: { Start: dayBeforeYesterday, End: yesterday},
    Metrics: ["UNBLENDED_COST"],
    GroupBy: [
      {
        Type: "DIMENSION",
        Key: "LINKED_ACCOUNT"
      }]
  };

  const paramsDayBeforeYesterday = {
    Granularity: "DAILY",
    TimePeriod: { Start: twoDaysBeforeYesterday, End: dayBeforeYesterday},
    Metrics: ["UNBLENDED_COST"],
    GroupBy: [
      {
        Type: "DIMENSION",
        Key: "LINKED_ACCOUNT"
      }]
  };

  // get cost for yesterday and the day before yesterday
  const getCostsYesterday = await costexplorer.getCostAndUsage(paramsYesterday).promise();
  const getCostsDayBeforeYesterday = await costexplorer.getCostAndUsage(paramsDayBeforeYesterday).promise();

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
  
  return percentageIncrease;
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