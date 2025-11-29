{%
// Required arguments
if (!key) {
    fprintf(stderr, "Missing API key\n");
    exit(2);
}
if (!host) {
    fprintf(stderr, "Missing host\n");
    exit(2);
}
if (!op) {
    fprintf(stderr, "Missing op\n");
    exit(2);
}

// Determine endpoint and payload based on op
let endpoint;
let payloadObj = { op: op };

if (op == "load" || op == "merge") {
    endpoint = "/config-file";
    if (op_arg.file) {
        payloadObj.file = op_arg.file;
    } else if (op_arg.string) {
        payloadObj.string = op_arg.string;
    } else {
        fprintf(stderr, "Unsupported op_arg\n");
        exit(2);
    }
}
else if (op == "showConfig") {
    endpoint = "/retrieve";
    if (op_arg.path) {
        payloadObj.path = op_arg.path;
    } else {
        // default: whole config
        payloadObj.path = [];
    }
}
else {
    // unsupported op
    fprintf(stderr, "Unsupported op: %s\n", op);
    exit(3);
}

// Convert payload to JSON string
let payloadStr = sprintf("%J", payloadObj);

// Build the curl command
function quoteForShell(s) {
    if (s == null) return "''";
    let parts = split(s, "'");
    return "'" + join("'\"'\"'", parts) + "'";
}

let url = host + endpoint;

let cmd = sprintf(
    "curl -skL --connect-timeout 3 -m 5 -X POST %s " +
    "--form-string data=%s --form key=%s",
    quoteForShell(url),
    quoteForShell(payloadStr),
    quoteForShell(key)
);


//let rc = system(cmd);

let proc = fs.popen(cmd, "r");
if (!proc) {
        fprintf(stderr, "Failed to start curl\n");
        return null;
}

let out = proc.read("all");
proc.close();

%}
{{out}}
