# ivideon-debian
Automation script to install &amp; configure Ivideon on clean Debian install

## Use case

Linux box runs Ivideon video server and connects to your home network through OpenVPN to a VLAN with network cameras. The video server (must be configured after installation separately, so that it authenticates to the video cameras) pulls video over TLS ciphered (Open VPN) channel, processes it locally and uploads to Ivideon cloud over HTTPS.

This script creates a user 'videouser' with regular home dir, downloads & installs:

 * X11 env: Xorg, GDM3 and Gnome basic desktop
 * ivideon-video-server
 * OpenVPN
 
then enables OpenVPN and ivideon-video-server services at startup.

After running this script, one must manually configure ivideon-video-server with credentials of cameras to pull video from.
