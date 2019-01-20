var Web3 = require('web3');
var web3 = new Web3(new Web3.providers.HttpProvider("http://localhost:8545"));

/* web3.eth.getBlockNumber(function(error, result){ if(!error) console.log(result) }) */
var defaultAcc = "";

let logQueue = [];
let transactionsList = [];
let loggerRunning = false;

setDefaultAccount();

function server() {

  var user = {
    'userA': 'pwd123',
    'userB': 'pwd456',
    'userC': 'pwd789',
    'userD': 'pwd012',
    'userE': 'pwd345'
  };

  var fileX = "This is the file from server";
  var filePermissionBit = {}
  var loginStatus = {}

  // Set file permission and login status of every user
  for (u in user) {
    filePermissionBit[u] = 0;
    loginStatus[u] = 0;
  }

  // Login function which logs if success
  this.user_Login = function(userId, pwd) {
    if (user[userId] == pwd) {
      loginStatus[userId] = 1;
      // Send the log to blockchain
      let event = userId + " Login";
      bkc_logging(event);
    }
  }

  // A utility function to check if user is already logged in
  function _isLoggedIn(userId) {
    return loginStatus[userId] == 1;
  }

  // Logout function which logs if user is logged out successfully
  this.user_Logout = function(userId) {
    if (_isLoggedIn(userId)) {
      loginStatus[userId] = 0;
      // Send the log to blockchain
      let event = userId + " Logout";
      bkc_logging(event);
    }
  }

  // A function to set file permission for the user
  this.file_permission_set = function(user) {
    if (_isLoggedIn(user)) {
      filePermissionBit[user] = 1;
      // Send the log to blockchain
      let event = "file permission set for the user:  " + user;
      bkc_logging(event);
    } else {
      console.log("Setting file permission failed, since user was not logged in");
    }
  }

  // A function to assign reading permission to other user
  this.file_delegate = function( delegator,  delegatee) {
    if (_isLoggedIn(delegator) && _isLoggedIn(delegatee)) {
      if (filePermissionBit[delegator] == 1) {
        let event = delegator +" giving file-read permission to "+delegatee;
        bkc_logging(event);
        //console.log(delegator +" giving file-read permission to "+delegatee);
        filePermissionBit[delegatee] = 1;
      } else {
        console.log("Delegator doesn't have permissions for the file");
      }
    } else {
      console.log("File delegation failed since one of the delegator or delegatee was not logged in");
    }
  }

  // A function which returns the file if a user has access to read it
  this.file_Access = function(user) {
    if (loginStatus[user] == 1 && filePermissionBit[user] == 1) {
      // Send the log to blockchain
      let event = user + " reading file: " + fileX;
      bkc_logging(event);
      return fileX;
    }
    let event = user + " is not authorized to read this file";
    bkc_logging(event);
    return "You are not authorized to read this file.";
  }

  // A function which returns transaction (log), takes transaction id as an input
  this.getTransactionLog = function(id, cb) {
    web3.eth.getTransaction(id, function(error, result) {
      if (error) {
        cb("Error occured while fetching the transaction: ", id);
      } else {
        if (result != undefined) {
          cb(decrypt(result.input));
        }
      }
    });
  }

  /*Function to generate hex encoded value for input string & sending transaction to blockchain for logging puropse*/
  function bkc_logging(str){

    // I am using a queue to send logs into the blockchain and sending one log at a time
    logQueue.unshift(encrypt(str));
    if (!loggerRunning) {
      logEvent();
    }
  }

  // This function runs as long as there are logs in the queue
  function logEvent() {
    loggerRunning = true;
    let log = logQueue.pop();
    sendTransaction(log, function() {
      if (logQueue.length != 0) {
        logEvent();
      } else {
        loggerRunning = false;
      }
    });
  }

  // This send a log message as a transaction in blockchain
  function sendTransaction(msg, cb) {
    // There is no need to have `to` (receiver) field in the request

    web3.eth.sendTransaction({
        from: defaultAcc,
        data: msg
      }, function(error, result) {
        if (error) {
          console.log("Error occured while sending the transaction => ", error);
        } else {
          // Add the transaction id in the list
          transactionsList.push(result);
        }
        cb();
      }
    );
  }

}

function client(){
  server1 = new server();
  this.execute = function() {

    /*
      If you try to run all the test cases at the same time,
      then the logs will be printed multiple times
      since I am iterating transactionsList to print the logs
      and every test case prints logs at that moment from the
      transactionsList.
      Therefore, uncomment one and comment the rest for the testing
      purpose.
    */

    testcase1(server1);
    //testcase2(server1);
    //testcase3(server1);

  }

  function testcase1(serverObj) {
    console.log("\n", "Running Test case 1");

    serverObj.user_Login("userA", "pwd123");
    serverObj.user_Login("userB", "pwd456");

    serverObj.file_permission_set("userA");
    var response = serverObj.file_Access("userA");
    response = serverObj.file_Access("userB");

    serverObj.file_delegate("userA", "userB");
    response = serverObj.file_Access("userB");

    serverObj.user_Logout("userA");
    serverObj.user_Logout("userB");

    setTimeout(function() {
      getAllTransactions();
    }, 2000);
  }

  function testcase2(serverObj) {
    console.log("\n", "Running Test case 2");

    serverObj.user_Login("userE", "pwd345");
    serverObj.user_Login("userD", "pwd012");
    serverObj.file_delegate("userE", "userD");
    response = serverObj.file_Access("userD");

    serverObj.file_permission_set("userD");
    response = serverObj.file_Access("userD");

    serverObj.user_Login("userC", "pwd789");
    response = serverObj.file_Access("userC");
    serverObj.file_delegate("userD", "userC");
    response = serverObj.file_Access("userC");

    serverObj.user_Logout("userC");
    serverObj.user_Logout("userD");
    serverObj.user_Logout("userE");

    setTimeout(function() {
      getAllTransactions();
    }, 2000);

  }

  function testcase3(serverObj) {
    console.log("\n", "Running Test case 3");

    serverObj.file_permission_set("userA");
    serverObj.user_Login("userA", "pwd123");
    //response = serverObj.file_Access("userA");
    serverObj.file_permission_set("userA");
    response = serverObj.file_Access("userA");

    serverObj.file_delegate("userA", "userE");

    serverObj.user_Login("userE", "pwd345");
    response = serverObj.file_Access("userE");
    serverObj.file_delegate("userA", "userE");
    response = serverObj.file_Access("userE");

    serverObj.user_Logout("userE");
    serverObj.user_Logout("userA");

    setTimeout(function() {
      getAllTransactions();
    }, 2000);
  }

  // Function used to print all the transaction logs
  function getAllTransactions() {
    console.log("A list of transaction ids ", '\n', transactionsList);
    console.log("==== Printing the logs after getting transactions from the blockchain ====");
    for (let i in transactionsList) {
      setTimeout(function() {
        server1.getTransactionLog(transactionsList[i], function(str) {
          console.log(str)
        });
      }, i * 1000);
    }
  }

}

// Encyrpts a string to hex format
function encrypt(str) {
  // Can also use web3.toHex(str)
  return "0x" + new Buffer(str).toString('hex');
}

// Decyrpts a hex to string format
function decrypt(hex) {
  // Can also use web3.toAscii(hex)
  // Substring done to remove 0x from the hex
  return new Buffer(hex.substring(2), 'hex').toString();
}

/*Function to get a account from local blockchain*/
function setDefaultAccount(){
  web3.eth.getAccounts(function(error, result){
    if(!error){
      defaultAcc  = result[0];
      var client1 = new client();
      client1.execute();
    }
  });
}

/*
geth --datadir bkc_data --rpcapi "eth,net,web3,personal" --networkid 89992018 --bootnodeenode://d3cd4e70fe7ad1dd7fb23539c53982e42816b4218cc370e8af13945f7b5e2b4a288f8b949dbdba6a998c9141266a0df61523de74490c91fc1e3d538b299bb8ab@128.230.208.73:30301 console 2>console.log
*/
