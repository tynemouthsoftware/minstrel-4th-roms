ZX80 4K Integer BASIC modfied to run on Minstrel 4th hardware.

For more info, see the following posts.

* http://blog.tynemouthsoftware.co.uk/2023/11/zx80-basic-on-the-minstrel-4d-part-1.html
* http://blog.tynemouthsoftware.co.uk/2023/12/zx80-basic-on-the-minstrel-4d-part-2.html
* http://blog.tynemouthsoftware.co.uk/2023/12/zx80-basic-on-the-minstrel-4d-part-3.html
* http://blog.tynemouthsoftware.co.uk/2023/12/zx80-basic-on-the-minstrel-4d-part-4.html

The speed should be the same as a ZX80. Rather than generating a video picture, it parses the display file and copies it into Minstrel 4th display RAM.

LOAD and SAVE routines have been replaced, and include progress indicator.

Keyboard is remapped for the changes to the middle 8 keys, some games may use their own scanning routines.

Many flicker-free games should work, although some may cause a click, see the part 3 post above for a small changes necessary to stop that.

The original ROM is 4K, the new display code as been added in the space after that to make an 8K ROM.

It should be padded out to 16K if building a Minstrel 4th ROM set.
