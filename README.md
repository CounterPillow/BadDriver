BadDriver
=========

BadApple but on the Logitech G15 LCD, without G15Daemon or LibG15, just raw HID access.

Preparing the Data
------------------

```
ffmpeg -i nicovideo-sm8628149_4c8a655c13612a596d6b97c58797d3c622adebddc6436264e47e615fdccb9d21.mp4 -vf 'scale=-1:129,pad=480:130:-1,crop=480:129,fps=15,scale=160:43' '/tmp/badapple/badapple_%05d.png'
```
followed by
```
cd /tmp/badapple/
mkdir out
gm mogrify -output-directory out -format ppm -monochrome 'badapple_*.png'
```


Compiling
---------

```
dub build
```


Running
-------

If you don't have udev rules for the G15, you'll need to run `baddriver` as root. Otherwise, just run `baddriver` (and make sure nothing else like G15Daemon is hogging the USB device.)
