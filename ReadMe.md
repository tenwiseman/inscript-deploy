# inscript-deploy
A collection of network share resident powershell scripts to preconfigure (machine name, IP settings) a build of Windows 10 and further deploy from a CLI menu an administrator selected choice of applications. The installation commands and machine details for this are defined in a simple JSON template.
## Installation
1. Copy files to a network share which will be directly accessible from the target machine
2. Have a brief look at the file Deployment\shell\templates\template.json
3. Create a folder Deployment\files and create folders within for application files making equivalent matching changes in template.json to run the appropriate install commands (.cmd or .au3).
4. At the top of template.json, make appropriate changes to properly name and network a target machine, also giving it an identifier. 
## Usage
1. Run up target machine and adjust networking (DHCP?) to see share
2. Run elevated the file 'install.cmd'. You will see the following
<pre>
-------------------------------------------------------------------------------------------------
 ## Inscript-Deployment Script
 ## By Tenwiseman, 2017

 ? ISM_MACHINE_ID =  
 * This machine ID is undefined or does not exist in the template file!
 * Please assign a valid one from this list!
 .-----------------------------------------------------------------------------------------------.
 |   identifier: Win10Eval-CCTV2    identifier: Win10Eval-CCTV3    identifier: Win10Eval-VMWARE1 |
 |           CN: CCTV2                      CN: CCTV3                      CN: VMWARE1           |
 |     template: cctv                 template: cctv                 template: cctv              |
 |       IPaddr: 192.168.3.55           IPaddr: 192.168.3.23           IPaddr: 192.168.3.24      |
 |       GWaddr: 192.168.3.254          GWaddr: 192.168.3.254          GWaddr: 192.168.3.254     |
 |      DNSaddr: 192.168.3.254         DNSaddr: 192.168.3.254         DNSaddr: 192.168.3.254     |
 |                                                                                               |
 '-----------------------------------------------------------------------------------------------'
 Enter ID [ ]: Win10Eval-CCTV2

 * ISM_MACHINE_ID = Win10Eval-CCTV2
 * This machine will be configured using these settings
 .---------------------------------.
 |   identifier: Win10Eval-CCTV2   |
 |           CN: CCTV2             |
 |     template: cctv              |
 |       IPaddr: 192.168.3.55      |
 |       GWaddr: 192.168.3.254     |
 |      DNSaddr: 192.168.3.254     |
 '---------------------------------'
 .- cctv --------------------------------------.
 | .- current run settings ------------------. |
 | |             dummyRun: False             | |
 | |       activeTemplate: cctv              | |
 | |           singleStep: False             | |
 | '-----------------------------------------' |
 | menu commands:                              |
 |        q  Quit this menu                    |
 |        r  Restart whole script              |
 |                                             |
 | main commands:                              |
 |     /set  settings menu                     |
 |     /mid  Reset Machine ID                  |
 |     /run  Install ALL of the following      |
 |                                             |
 | common commands:                            |
 |     alnk  Create Script Desktop Shortcut    |
 |     anam  Change Computer Name              |
 |     anet  Change Network Configuration      |
 |     auto  Copy autoIT3.exe executable       |
 |                                             |
 | cctv commands:                              |
 |       d1  Install HEM Client                |
 |       d2  Install HEM Utilities             |
 |                                             |
 '---------------------------------------------'
Enter Choice : 
------------------------------------------------------------
</pre>
## Credits
Tenwiseman, 2017.
## License
Free licence to do whatever. Just give me a credit like the line above, that's all :)
## Contributing
1. Fork it!
2. Create your feature branch: 'git checkout -b my-new-feature'
3. Commit your changes: 'git commit -am'

Add some feature. Submit a pull request :)
## History
Apr 2017 - It's my first trip on GitHub, please be gentle... ;-)

