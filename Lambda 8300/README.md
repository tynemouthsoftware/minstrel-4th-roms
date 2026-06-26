Lambda 8300 8K Floating Point BASIC modfied to run on Minstrel 4th hardware.

For more info, see the following posts.
* [http://blog.tynemouthsoftware.co.uk/2026/06/lambda-8300-reverse-engineering.html](http://blog.tynemouthsoftware.co.uk/2026/06/lambda-8300-reverse-engineering.html)
* [http://blog.tynemouthsoftware.co.uk/2025/06/a-zx81-game-on-a-zx81-emulator-on-a-jupiter-ace-emulator.html](http://blog.tynemouthsoftware.co.uk/2019/12/a-minstrel-3-based-clone-of-the-lambda-8300-ZX81-clone.html)
* [http://blog.tynemouthsoftware.co.uk/2025/06/zx81-basic-on-minstrel-4th-original.html](http://blog.tynemouthsoftware.co.uk/2019/12/a-minstrel-3-based-clone-of-the-lambda-8300-ZX81-clone.html)

In FAST mode, the speed should be the same as a Lambda 8300. Rather than generating a video picture, it parses the display file and copies it into Minstrel 4th display RAM.

SLOW mode is supported, this uses a fast copy as the Lambda 8300 has a fixed location, always fully expanded display file. This currently runs at 360% the speed of a ZX81.

LOAD and SAVE routines have been replaced, and include progress indicator.

The SOUND and MUSIC routines, and the keyboard beep have been updated to use the Minstrel 4th hardware.
The original ROM is 8K, the new display code as been added in the additional 5K ROM space available on the Minstrel 4h to make a 16K ROM image.

48K of RAM is detected, as the display file is fixed location and will always be below $8000, the full RAM can be used.
