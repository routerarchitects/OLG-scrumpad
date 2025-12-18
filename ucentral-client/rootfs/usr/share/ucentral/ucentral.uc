#!/usr/bin/ucode
push(REQUIRE_SEARCH_PATH,
	"/usr/lib/ucode/*.so",
	"/usr/share/ucentral/*.uc");

let schemareader = require("schemareader");
let fs = require("fs");
let ubus = require("ubus").connect();
let vyos = require("vyos.config_prepare");
let vyos_api = require("vyos.https_server_api");
let inputfile = fs.open(ARGV[0], "r");
let inputjson = json(inputfile.read("all"));
let custom_config = (split(ARGV[0], ".")[0] != "/etc/ucentral/ucentral");

let error = 0;

inputfile.close();
let logs = [];

function get_host_api_key() {
	// Use backslashes to escape the internal double quotes
	let cmd = "/opt/vyatta/bin/vyatta-op-cmd-wrapper show configuration commands | grep \"api keys\" | cut -d\"'\" -f2";
	let proc = fs.popen(cmd, "r");
	if (!proc) {
		fprintf(stderr, "CLI command failed\n");
		return null;
	}
	let out = proc.read("all");
	proc.close();
	return out;
}

try {
	let host = "https://127.0.0.1";
	let key = get_host_api_key();         	
	let state = schemareader.validate(inputjson, logs);
	let op_arg = { };
	vyos_config_payload  = vyos.vyos_render(state, key);
	op_arg.string = vyos_config_payload;
	let op = "load";
	let rc = vyos_api.vyos_api_call(op_arg, op, host, key);
	if(rc != ''){
		rc = json(rc);
	}
	if(rc != '' && rc.success == false){
		error = 1;
	}

}
catch (e) {
	error = 2;
	warn("Unable to contact the vyos api server: ", e, "\n", e.stacktrace[0].context, "\n");
}

if (inputjson.uuid && inputjson.uuid > 1 && !custom_config) {
	let text = [ 'Success', 'Rejects', 'Failed' ];
	let status = {
		error,
		text: text[error] || "Failed",
	};
	if (length(logs))
		status.rejected = logs;

	ubus.call("ucentral", "result", {
		uuid: inputjson.uuid || 0,
		id: +ARGV[1] || 0,
		status,
	});
	if (error > 1)
		exit(1);
}
