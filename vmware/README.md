# Booting service in vcloud using upload script

## Dependencies:
- ovftool: https://my.vmware.com/web/vmware/details?downloadGroup=OVFTOOL400&productId=353 I recommend putting it in `/Applications/VMware OVF Tool/ovftool` on mac, which is where it installs by default. 
- includeos-tools: https://github.com/includeos/includeos-tools.git

## Steps
1. Compile service with vmxnet3 `boot -b .`
2. Enter build folder and run `$INCLUDEOS_SRC/etc/vmware <name_of_service_no_extension>`. This will create all necessary vmware files and boot with fusion. Let's you know if it boots correctly. 
3. Enter newly created folder. The folder name is the timestamp from when the vmware command was run. e.g. `/IncludeOS/examples/acorn/build/20170529_115844/0`
4. Configure credentials in `includeos-tools/vmware/upload_to_vcloud.sh`:
```
vcloud_address=""   # Address to vcloud e.g. vcloud.basefarm.no
username=""         # Username used to log in to vcloud
org=""              # Org used in the vcloud e.g. IOS
vapp=""             # Name of the vapp that is uploaded
```
5. Upload ova to vcloud. `includeos-tools/vmware/upload_to_vcloud.sh <name_of_service>.ova`. You need to enter your vcloud password.
6. Log in to vcloud manually and when upload is complete right click vm and select `start`. 
