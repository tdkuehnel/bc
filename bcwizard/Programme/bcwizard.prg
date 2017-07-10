LPARAMETERS p1,p2,p3,p4,p5,p6,p7,p8,p9
? _vfp.application.fullname

* Alle Assistenen ausser PROJECT und APPLICATION umleiten nach wizard.app
if (type("p1") == "L") or ((type("p1") == "C" and p1 != "PROJECT") and (type("p1") == "C" and p1 != "APPLICATION"))
	if type("p1") = "C"
		? "Assistenten umgeleitet über bcwizard.app. p1: "+p1
	else
		? "Assistenten umgeleitet über bcwizard.app. p1: <>"
	endif
	do home()+"wizard.app" with p1,p2,p3,p4,p5,p6,p7,p8,p9
	return
endif

if type("p1") = "C"
	? "eigener Generator. Parameter p1: "+p1
else
	? "eigener Generator. Parameter p1: <>"
endif

* Als Generator von einem vorhandenen Projekt aufgerufen
if (type("p1") == "C" and p1 == "PROJECT") 
	set default to (_vfp.activeproject.homedir)
	if not file("daten\bcapp.dbf")
		if messagebox("Keine Steuerdatei gefunden. Projekt "+_vfp.activeproject.name+" initialisieren?",36,"bcApp Generator") = 6
			do createappdata
		else
			return
		endif	
	endif
	do dogenerator
endif

* Als Assistent für eine neue Anwendung aufgerufen
if (type("p1") == "C" and p1 == "APPLICATION")
	public onewappconfig
	onewappconfig = newobject("newappconfig", "bcwizard")
	do form newapp.scx
	if empty(onewappconfig.homedir)
		=messagebox("ungültiges Projektverzeichnis", 48, "bcApp Generator")
		? "release onewappconfig"
		release onewappconfig
		return
	endif
	if onewappconfig.returnvalue = .t.
		if not directory(onewappconfig.fullpath)
			mkdir (onewappconfig.fullpath)
		endif
		set default to (onewappconfig.fullpath)
		create project (onewappconfig.fullpath+onewappconfig.appname) nowait save in screen noshow noprojecthook
		if onewappconfig.createdir
			do createdirectories
		endif
		if onewappconfig.installhook
			do installhook
		endif
		if onewappconfig.installbcapp
			do createappdata
			do dogenerator
		endif
		_vfp.activeproject.visible = .t.			
	endif
	? "release onewappconfig"
	release onewappconfig
endif

procedure installhook
if file("Klassen\"+alltrim(onewappconfig.appname)+"_hook.vcx")
	=messagebox("Klassendatei Klassen\"+alltrim(onewappconfig.appname)+"_hook.vcx bereits vorhanden.", 32, "bcApp Generator")
else
	create classlib "Klassen\"+alltrim(onewappconfig.appname)+"_hook.vcx"
	add class bchook of bcwizardhooks to "Klassen\"+alltrim(onewappconfig.appname)+"_hook.vcx"
	_vfp.activeproject.projecthooklibrary = sys(5)+sys(2003)+"\Klassen\"+alltrim(onewappconfig.appname)+"_hook.vcx"
	_vfp.activeproject.projecthookclass = "bchook"	
endif
endproc

procedure createdirectories
	if not directory("Daten")
		mkdir "Daten"
	endif
	if not directory("Formulare")
		mkdir "Formulare"
	endif
	if not directory("Klassen")
		mkdir "Klassen"
	endif
	if not directory("Berichte")
		mkdir "Berichte"
	endif
	if not directory("Programme")
		mkdir "Programme"
	endif
endproc

procedure dogenerator
	use "daten\bcapp" in 0
	public obcapp
	select bcapp
	scatter name obcapp
	do form generator
	select bcapp
	gather name obcapp
	? "release obcapp"
	use in bcapp
	release obcapp
endproc

procedure createappdata
	if not directory("Daten")
		mkdir "Daten"
	endif
	open database bcwizard
	set database to bcwizard
	use app in 0
	use wizard in 0
	select app
	copy structure to "Daten\bcapp.dbf"
	insert into daten\bcapp values (.t.,.f.,.f.,.f.,.f.,wizard.skeleton_path)
	use
	use in bcapp
	use in wizard
	close databases
endproc
