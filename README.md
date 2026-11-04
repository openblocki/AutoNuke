# AutoNuke
Vac-Nuke Manager for GTNH  </br>
Made for usage to be a Simple as Possible </br>

INFO: While in Overriden State the Reactor will not be Controlled or Maintained by AutoNuke for that it has to be taken out of Override either by Deleting their Reactor File from the Database, or using the ReActivate Button in the UI </br>
If the Reason for its override is not Resolved it may get overriden again </br>

INFO: If your Reactor is SCRAMED, deactivating the Override is not recommendet, as it may be Close to exploding. Either Contain it and Safely Detonate it or use Overclocked heat vents to Reduce Heat. </br>
Reactors SCRAM Automatically if their Heat goes over 50%. (95% for MOX, High Density Plutonium, Excited Plutonium and Naquadria [By Default the Script does not Handle Naquadria]) </br>

INFO: The Program does not know or Judge if the Coolant Cell is enough for your Fuel Rod, it will try its best to manage it. </br> 
Using fuels like "The Core" with Helium Coolant is Probably a Bad Idea. </br>

INFO: The Program will not Stop the Reactor from Running if its Missing Fuel Cells since that will only Decrease Output and not increase Heat

WIP Reactors warm up Automatically to 90% Heat during Setup Phase if they recognize any of the MOX based Fuel Rods. </br>
Any of these Thresholds can be configured to your liking in ```reactor_conf.lua```. This is not recommended though

Reactor Setup: </br>
<img width="2560" height="1057" alt="2026-11-03_15 16 56" src="https://github.com/user-attachments/assets/590f0939-c753-4ee8-84e7-4047e912c346" />

Adapter can be Placed on any of the 4 side Chambers</br>
<img width="2560" height="1057" alt="2026-11-03_15 17 01" src="https://github.com/user-attachments/assets/393c1441-c23f-44c4-99fc-38516c87614d" />

Interface can be filled With any Supportet Coolant or Rod. The Programm recognizes the Coolant and Fuel Rods Automatically when its Registering the Reactor
<img width="2560" height="1057" alt="2026-11-03_15 17 03" src="https://github.com/user-attachments/assets/e1a4b31d-eb15-4768-a7dd-c871ac95663f" />

<img width="2560" height="1057" alt="2026-11-03_15 17 13" src="https://github.com/user-attachments/assets/8794efc8-949a-446a-a678-f6ac74b1f57a" />

!NOT IN THE CORNERS!</br>

Each Adapter, Transpoder and Redstone IO can only touch one Reactor or else it wont work</br>

I Recommend Installing after Building the Reactors as they only get Registered during the Setup Phase => After a Reboot.</br>
Installation Instructions: </br>
1. run ```wget https://raw.githubusercontent.com/openblocki/AutoNuke/main/NukeInstaller.lua NukeInstaller.lua``` This Downloads the Installer for AutoNuke </br>
2. run ```NukeInstaller``` This Runs the Installer </br>
3. run ```reboot``` This allows the Computer to properly initialize everything and Auto Starts the Program </br>

Setup UI looks a bit bad Right now, but it should be readable

Currently Supportet Coolants:</br>
Helium</br>
NaK</br>
540k SP Coolant</br>
1080k SP Coolant</br>

Currently Supportet Fuel:</br>
Glowstone (Only meant for Testing)</br>
Uranium</br>
MoX (Including Heat Capacity - System can't heat up by itself yet)</br>
High Density Uranium</br>
Excited Uranium</br>
High Density Plutonium</br>

## ```!INFO! This was made without the use of any AI. 100% Handmade.``` </br>


IMPORTANT TODOS: </br>
Rewrite Readme to look better and read easier.

Take better Pictures of the Setup Process

Allow the Programm to delegate Reactor Ticks to Multiple Servers / Tier 1 CPUs => Parallel Reactor Management
```
Idea:
    This Script runs on a Main PC / Server
    The Sub Servers just run the Reactor Tick Loop over and over with os.sleep(0.5) or os.sleep(0.1) to allow for yielding and event.listen()

    Main Script distributes the Reactors and Manages LSC, Database, Reactor Setup / Registration, User SCRAM / ShutOff events.
    Allows for more interactive UI since the Main PC doesnt waste too much Time on Reactor Management

    Manager does event.push("AN/MANAGER/PING") (or modem.broadcast) regulary. If a Sub Server goes without PING for more than 10 Cycles it Shuts off automaticaly.

    Sub Servers send event.push("AN/SERVER/PONG", {[reactor_data = {active = boolean, status = string, status_color = string, etc...}]}) for the main PC to Display the Reactor Data. Also maybe if main Server goes without PONG from a sub Server it sends a wake signal to that server => https://ocdoc.cil.li/component:modem and if it then doesnt receive a pong signal after like 5 seconds it shuts down the reactors of that server
```
