resource_manifest_version "44febabe-d386-4d18-afbe-5e627f4af937"
name "rp-radio"
description "An in-game radio which makes use of the TokoVOIP radio API for FiveM"
author "Frazzle (frazzle9999@gmail.com)"
version "v1.0"
ui_page "index.html"

dependencies {
	"tokovoip_script",
}

files {
	"index.html",
	"on.ogg",
	"off.ogg",
}

client_scripts {
	"client.lua",
}

server_scripts {
	"server.lua",
}