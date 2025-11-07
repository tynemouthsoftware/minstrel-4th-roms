ZX81 8K Floating Point BASIC modfied to run on Minstrel 4th hardware.

For more info, see the following posts.

* http://blog.tynemouthsoftware.co.uk/2025/05/zx81-basic-on-minstrel-4th.html
* http://blog.tynemouthsoftware.co.uk/2025/06/a-zx81-game-on-a-zx81-emulator-on-a-jupiter-ace-emulator.html
* http://blog.tynemouthsoftware.co.uk/2025/06/zx81-basic-on-minstrel-4th-original.html

In FAST mode, the speed should be the same as a ZX81. Rather than generating a video picture, it parses the display file and copies it into Minstrel 4th display RAM.

SLOW mode is supported, a delay has been added to make the speed match that of a PAL / UK / 50Hz ZX81.

Alternate ROM versions are supplied with different delays. There is one where SLOW mode is approximately twice as fast as a ZX81 in SLOW mode.

Another alternative version matches 100% of the speed of an NTSC / US / 60Hz TS1000.

LOAD and SAVE routines have been replaced, and include progress indicator.

Keyboard is remapped for the changes to the middle 8 keys, some games may use their own scanning routines.

The original ROM is 8K, the new display code as been added in the additional 5K ROM space available on the Minstrel 4h to make a 16K ROM image.

16K of RAM is detected. A further 32K is available for certain applications, although it is not detected or used by BASIC.
