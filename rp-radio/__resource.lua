resource_manifest_version "44febabe-d386-4d18-afbe-5e627f4af937"

ui_page "index.html"

dependencies {
	"tokovoip_script",
	"policejob",
	"emsjob",
	"core_modules",
	"core",
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