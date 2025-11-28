#!/usr/bin/ucode
push(REQUIRE_SEARCH_PATH,
	"/usr/lib/ucode/*.so",
	"/usr/share/ucentral/*.uc");

let schemareader = require("schemareader");
let fs = require("fs");
let ubus = require("ubus").connect();
let vyos_config_gen = require("vyos_config_gen");
let vyos = require("vyos_config_gen");

let inputfile = fs.open(ARGV[0], "r");
let inputjson = json(inputfile.read("all"));
let custom_config = (split(ARGV[0], ".")[0] != "/etc/ucentral/ucentral");

let error = 0;

inputfile.close();
let logs = [];

let args_path = "/etc/ucentral/vyos-info.json";
let args = {};

if (fs.stat(args_path)) {
    let f = fs.open(args_path, "r");
    args = json(f.read("all"));
    f.close();
}

let op   = (ARGV.length > 1 && ARGV[1] != "-") ? ARGV[1] : (args.op   ?? null);
let host = (ARGV.length > 2 && ARGV[2] != "-") ? ARGV[2] : (args.host ?? null);
let key  = (ARGV.length > 3 && ARGV[3] != "-") ? ARGV[3] : (args.key  ?? null);

if (!op || !host || !key) {
    print("Missing op/host/key. Provide them in /etc/ucentral/vyos-info.json or pass '-' placeholders and ensure file exists.\n");
    exit(1);
}

try {
	for (let cmd in [ 'rm -rf /tmp/ucentral',
			  'mkdir /tmp/ucentral',
			  'rm /tmp/dnsmasq.conf',
			  '/etc/init.d/spotfilter stop',
			  'touch /tmp/dnsmasq.conf' ])
		system(cmd);

	let state = schemareader.validate(inputjson, logs);
	printf("Input Json is %s\n\n", state);
	let config = state;
	let cli_text = vyos_config_gen.vyos_render(config);
	let scope = {cli_text, op, host, key};
	let rc = include('vyos_api_caller.uc', scope);
	if(rc != 0){
	    error = 0;
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
