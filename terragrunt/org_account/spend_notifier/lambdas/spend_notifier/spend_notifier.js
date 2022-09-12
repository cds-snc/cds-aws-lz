const AWS = require('aws-sdk');
const costexplorer = new AWS.CostExplorer({ region: 'us-east-1' });
const organizations = new AWS.Organizations({ region: 'us-east-1' });

const https = require('https')

exports.handler = async (event) => {
  const hook = event.hook;
  const today = new Date();
  const accountCost = await getAccountCost()
  let accounts = await getAccounts()
  Object.keys(accounts).forEach(key => {
    if(accountCost.hasOwnProperty(key)){
      accounts[key]["Cost"] = accountCost[key]
    } else {
      accounts[key]["Cost"] = 0
    }
  })
  let BU = {}

  Object.values(accounts).forEach(account => {
    if (BU.hasOwnProperty(account["BU"])) {
      BU[account["BU"]] = BU[account["BU"]] + account["Cost"]
    } else {
      BU[account["BU"]] = account["Cost"]
    }
  })
  const totalCost = Object.values(BU).reduce((a, b) => a + b, 0)

  const data = JSON.stringify(
    {
      "blocks": [
        {
          "type": "section",
          "text": {
            "type": "plain_text",
            "text": `Current AWS spend for ${(today.getMonth() + 1).pad(2)}-${today.getFullYear()}`,
            "emoji": true
          }
        },
        {
          "type": "section",
          "fields": Object.entries(BU).map(bu => (
            [{ "type": "mrkdwn", "text": `*${bu[0]}*` }, { "type": "mrkdwn", "text": `$${bu[1].toFixed(2).replace(/\d(?=(\d{3})+\.)/g, '$&,')} USD` }]
          )).flat()
        },
        {
          "type": "divider"
        },
        {
          "type": "section",
          "fields": [{ "type": "mrkdwn", "text": `*Total*` }, { "type": "mrkdwn", "text": `$${totalCost.toFixed(2).replace(/\d(?=(\d{3})+\.)/g, '$&,')} USD` }]
        },
      ]
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
    results[account["Id"]] = { Name: account["Name"], BU: tags.Tags.find(tag => tag["Key"] == "Business Unit").Value }
  }
  return results
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
