var/frog_nation_anger = 0
var/gamemode_map = ""
var/gamemode

client/var/vote

world
	fps = 40
	name = "Cowed Revival"
	view = "15x17"
	hub = "CowedRevival.CowedRevival"
	hub_password = "CijzH7cDKwBr9Kio"
	cache_lifespan = 0
	mob = /mob/character_handling
	turf = /turf/underground/dirtwall
	area = /area/darkness/underground
	loop_checks = 0 //Required for cave generation
	New()
		if(world.port) world.log = file("data/logs/world_log_" + time2text(world.realtime, "DD_MM_YY") + ".txt")
		chat_log = file("data/logs/chat_log_" + time2text(world.realtime, "DD_MM_YY") + ".htm")
		LoadCkey2Key()
		admin = new/global_admin
		update_status()
		. = ..()

		var/proceed = 0
		while(proceed < 1)
			sleep(10)
			for(var/mob/M in world)
				if(M.client)
					if(M.client.vote == "peasant")
						proceed++
					else if(M.client.vote == "kingdom")
						proceed++
					else if(M.client.vote == "random")
						proceed++
		/*world << "You have 60 seconds to vote for this round's Gamemode!"
		sleep(100)
		world << "50 seconds remaining!!"
		sleep(100)
		world << "40 seconds remaining!!"
		sleep(100)
		world << "30 seconds remaining!!"
		sleep(100)
		world << "20 seconds remaining!!"
		sleep(100)
		world << "10 seconds remaining!!"
		sleep(100)*/
		var/peasant,kingdom,random

		for(var/mob/M in world)
			if(M.client)
				if(M.client.vote == "peasant")
					peasant++
				else if(M.client.vote == "kingdom")
					kingdom++
				else
					random++

		if(peasant > kingdom && peasant > random)
			gamemode = "Peasant"
			world << "Gamemode - Peasant"
		else if(kingdom > peasant && kingdom > random)
			gamemode = "Kingdom"
			world << "Gamemode - Kingdom"
		else
			world << "Gamemode - Random"
			if(prob(50))
				gamemode = "Kingdom"
			else
				gamemode = "Peasant"

		for(var/mob/character_handling/M in world)
			if(M.client)
				spawn()
					M.Display()

		if(gamemode == "Peasant")
			for(var/obj/Decay_Object/I in world)
				I.Execute()

		world << "Generating world, may take up to two minutes!"

		sleep(10)

		LoadCowed()

		Month = 2
		Day = rand(1, 3)
		Hour = rand(8, 14)

		gametype = "normal" //testing
		game.Start()

		spawn(10)
			map_loaded = 1

			//update the scores of those that have just joined us
			for(var/player/P in global.admin.players)
				if(P.activity == -1 || P.activity <= world.realtime + 3000)
					spawn P.UpdateScore()

		// Berry Effects
		Random_Berry_Effects() // New Berry system

		berries = Make_Berry_Book()

		for(var/turf/Cave_Start/I in world)
			I.Generate()
		world << "Finished generating!"

/*		var/bbeff = pick(effects)
		bbeffect=bbeff
		effects-=bbeff
		var/rbeff = pick(effects)
		rbeffect=rbeff
		effects-=rbeff
		var/ybeff = pick(effects)
		ybeffect=ybeff
		effects-=ybeff
		var/blbeff = pick(effects)
		blbeffect=blbeff
		effects-=blbeff
		var/wbeff = pick(effects)
		wbeffect=wbeff
		effects-=wbeff
		berries={"
<title>Berrys</title>
<body>
<STYLE>BODY{font: 12pt 'Papyrus', sans-serif; color:black}</STYLE>
<table cellpadding="0" cellspacing="0" border="0" can_resize=1 can_minimize=0 align="center">
<td>
<center>
<b><u>Berries</u></b></br>
</br>
Berry  -  Effect</br>
</br>
Red Berry  -  [rbeffect]</br>
Black Berry  -  [blbeffect]</br>
Blue Berry  -  [bbeffect]</br>
Yellow Berry  -  [ybeffect]</br>
White Berry  -  [wbeffect]</br>
</td>
</table>
</body>
</html>
"}*/
	Del()
		dta_shutdown = 1

		//auto-expire round-expiration bans
		for(var/player/P in global.admin.players)
			for(var/player_punishment/W in P.punishments)
				if(W.expiration_rounds > 0)
					W.expiration_rounds--
					W.AutoExpire()

		for(var/mob/M in world)
			if(M.client)
				var/net_worth = 0
				for(var/item/misc/gold/I in M)
					net_worth += (I.stacked * 8)
				for(var/item/misc/copper_coin/I in M)
					net_worth += I.stacked
				net_worth -= M.initial_net_worth

				if(net_worth > 0) M.score_Add("taxes", net_worth)
		del admin

		SaveCowed()
		SaveCkey2Key()
		chat_log << "<b><font color=WHITE size=3>ROUND END</font><br />"
		return ..()
	proc
		update_status()
			world.name = "Cowed v[GAME_VERSION]"
			. = "Cowed v[GAME_VERSION] | "
			var/count = 0
			for(var/client/C) if(C.key) count++
			. += "[count]"
			if(max_players > 0) . += "/[max_players] players"
			else if(max_players == 0) . += " admins | Maintenance Mode"
			else . += " players"
			if(world.host || hostkey) . += " | Host: <a href=\"http://www.byond.com/members/[ckey(world.host) || ckey(hostkey)]\">[world.host || hostkey]</a>"
			if(status_message) . += " | [status_message]"
			world.status = .

fake_client
	var
		name
		key
		ckey
	New(key)
		src.name = key
		src.key = src.name
		src.ckey = ckey(key)
	proc
		CheckAdmin()
			for(var/client/C) if(C.ckey == src.ckey) . = C.CheckAdmin()
proc
	GetClients(include_admins = 0)
		. = new/list()
		for(var/client/C)
			if(include_admins || !C.admin) . += C
	GetAdmins(developers = 1, all_admins = 0)
		. = new/list()
		for(var/client/C)
			if(C.admin >= 10 && !developers) continue
			if(C.admin) .[C.ckey] = C
		if(all_admins)
			for(var/ckey in (developers ? admins : admins - developers)) if(!(ckey in .)) . += new/fake_client(ckey)
		for(var/ckey in .)
			if(istext(ckey))
				. += .[ckey]
				. -= ckey
	LoadCowed()
		var/savefile/F = new("cowed.sav")
		F["/settings/max_players"] >> max_players
		if(max_players == null) max_players = -1
		F["/settings/hostkey"] >> hostkey
		F["/settings/status"] >> status_message
		F["/admin_assoc"] >> admin_assoc
		F = null

		F = new("books.sav")
		F["/books"] >> books

		F = new("trekdoors.sav")
		for(var/obj/trekdoor/O in world)
			F.cd = "/[O.x]_[O.y]_[O.z]"
			O.Read(F)
	SaveCowed()
		var/savefile/F = new("cowed.sav")
		F["/settings/max_players"] << max_players
		F["/settings/hostkey"] << hostkey
		F["/settings/status"] << status_message
		F["/admin_assoc"] << admin_assoc
		F = null

		F = new("books.sav")
		F["/books"] << books

		if(fexists("trekdoors.sav")) fdel("trekdoors.sav")
		F = new("trekdoors.sav")
		for(var/obj/trekdoor/O in world)
			F.cd = "/[O.x]_[O.y]_[O.z]"
			O.Write(F)
	LoadCkey2Key()
		var/savefile/F = new("dta_ckey2key.sav")
		F >> dta_ckey2key
	SaveCkey2Key()
		var/savefile/F = new("dta_ckey2key.sav")
		F << dta_ckey2key

var
	gametype
	berries = "" //information on berries; put in healers' book automatically
	list
		bans
		kicks
		muted
		muted_ooc
		jailed //jailed players
		admin_assoc
		books
		tmp
			admin_pms
			gametypes = list("normal")
			admins
			developers = list("cowedrevival")//list("oasiscircle", "androiddata", "levian", "14mrh4x0r") //list of hard-coded sadmins (can't be removed)
			moderators = list ("monkeyhominid")//, "cowedrevival")
			//custom_music = list('sounds/music/data1.ogg', 'sounds/music/data2.ogg', 'sounds/music/data3.ogg', 'sounds/music/data4.ogg', 'sounds/music/data5.ogg')
			//custom_music = list('crossing.ogg', 'digsite.ogg', 'godmachine.ogg', 'godroom.ogg')
			custom_music = list('empire.ogg', 'zeelich.ogg', 'futurama2.ogg', 'futurama_ahhh.ogg', 'futurama_rhell.ogg', 'swamp.ogg', 'swamp2.ogg', 'llament.ogg', 'rollercoaster.ogg', 'kateboat.ogg')
			fonts = list('interface/fonts/PAPYRUS.TTF', 'interface/fonts/MinionPro.otf')
			MapObjectsByZ
	adminhelp = TRUE //if set, adminhelp verb can be used to call for assistance
	Month
	Day
	Hour
	Weather=""
	freeze_players = 0
	mob
		weregoat_cow
		weregoat/weregoat_goat
	music
	max_players = -1 //-1 = infinite, 0 = lockdown, >0 = limit
	hostkey
	status_message

	//berries
	bbeffect=""
	rbeffect=""
	blbeffect=""
	ybeffect=""
	wbeffect=""
	effects = list("Poison","Sleep","Heal","Hurt","Food","Alcohol")
	//worldz = 1
	abandon_mob = TRUE
	map_loaded = FALSE
	global_admin/admin
	dta_shutdown = 0

	undergroundz
	worldz
	skyz
	life_time = 0