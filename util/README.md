# signs-font-generate

This is a collection of helper shell scripts to create textures for
international characters to be used with the
[signs_lib](https://gitlab.com/VanessaE/signs_lib) Minetest mod.

They currently expect the
[Liberation Fonts](https://github.com/liberationfonts/liberation-fonts) to be
installed at "/usr/share/fonts/truetype/liberation".

ImageMagick is also required.

## Basic usage

sh create-signs-lib-overlay.sh <signs_lib_directory> <language-code>

For example, this command will write textures for the non-ASCII characters
of the French language to "/home/user/mcl_more_signs":

sh create-signs-lib-overlay.sh /home/user/mcl_more_signs fr

Currently, there is support for German (de), French (fr) and Polish (pl)
non-ASCII characters.

## Character alignment

I chose the image processing parameters in order fairly match the alignment of
the existing mcl_more_signs textures. In order to get even better alignment at
the expense of slightly smaller textures, it is possible to also replace
existing ASCII character textures:

sh write-ascii.sh <signs_lib_texture_directory>

For example, with mcl_more_signs residing at "/home/user/mcl_more_signs":

sh write-ascii.sh /home/user/mcl_more_signs/textures
