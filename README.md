# What is LACK? #
LACK stands for **Linux Appliance Construction Kit**.  LACK is a set of
scripts written in Perl and Bash that will take an existing installation, and
build minimized "packages" that can then be used on a system that runs off of
`initramfs`.

## Current LACK Workflow ##
1. Install donor system
1. Create recipe files using `lackpkgtool.sh`
  - The current shell script does not check for duplicate files 
1. Build a kernel and package an initramfs (`make_initramfs.sh`)
  - Update support packages (`loop-aes`, `ndiswrapper`) as needed
  - Update package info automatically with `debchange/dch`
1. Test via flash disk or PXEboot
1. Repeat from 2, or from 1 if a new distro comes out or you upgrade your host
  machine

## Planned LACK Workflow ##
1. Install donor system
1. Create recipe files using `lackpkgtool.pl`
  - `lackpkgtool.pl` will check for duplicate files and warn if any are found
  - Check for dependencies on binary files 
  - Check for dependencies on Perl modules
1. Create metapackages, which consist of groups of recipes (`metapkgtool.pl`)
1. Use the package tools to build packages and/or metapackages
  (`lackpkgtool.pl`)
1. Build a kernel
  - Update support packages (`loop-aes`, `ndiswrapper`) as needed
  - Update package info automatically with `debchange/dch`
1. Create an `initramfs` file (`make_initramfs.sh`)
  1. Check for kernel module dependencies (using `modules.dep`), and include
  any module dependencies that are missing
1. Test `initramfs` via flash disk or PXEboot
1. Repeat from 2, or from 1 if a new distro comes out or you upgrade your host
  machine

## Quick Introduction to Using LACK ##
- Install a base system using some sort of Debian-based distribution.
  Debian-based is required for now because the scripts are written to query
  `dpkg`.  Patches welcome if you want to support your favorite distro :)
- Build an install a kernel; the kernel modules will then become available for
  packacing in `/lib/modules`, and `gen_init_cpio` will become available in
  `/usr/src/linux` for creating the initramfs file.
- Use `lackpkgtool.sh` to generate a 'recpie' for a 'package'.  
  - A 'recipe' is a list of files formatted in such a way so that the
    `gen_init_cpio` tool can be run against it, in order to build either
    initramfs images or external squashfs package files
  - A LACK distribution will contain one or more of these recipes that will be
    used to build the initramfs image.  You can concatenate filelists together
    to make recipe/package management a little bit easier.
- Use `make_initramfs.sh` to create an Linux initramfs image.
- Once you have a new initramfs image, you can use something like
  `[sys|iso]linux` to boot from a USB stick or CD-ROM, or `pxelinux` to boot
  your new image over the network.  `pxelinux` is recommended because it
  vastly shortens development time, you don't have to re-upload the initramfs
  to your media, you just reboot the machine with the new initramfs image in
  place.

- Install base system
- Build a new kernel, or use an existing kernel
  - Building a new kernel will let you customize kernel modules and get you a
    copy of gen_init_cpio
  - Using a vendor's kernel will work for the lazy, but you will have to find
    some way to build `gen_init_cpio`, as it's usually not included in distro
    kernel packages
- Clone lack source for scripts and recipies
- Set up the initramfs.cfg file
  - `KERNEL_VER` (kernel version, points to the correct directory in
    /lib/modules, and also names the initramfs file)
  - `PROJECT_NAME` (used for the initramfs filename, and at the top/bottom of the /init script) 
  - `RELEASE_DATE` (used on banners,issue files, and the syslinux.cfg file)
  - `RELEASE_VER` (used on banners,issue files, and the syslinux.cfg file)
  - `LACK_PASS` (used in the issue file, so users know what password to log in
    with)
  - `PACKAGES`='list of packages' (list must be surrounded by single quotes,
    but can contain newlines, which the shell will strip out when it goes to
    include those filelist files in the initramfs filelist)
  - Call any other setup scripts, like find_first_free_filename and
    make_release_files.sh
- Generate common and/or project recipies using generate_recipe.sh
  - Use the sections_to_remove.txt files to exclude kernel modules from the
    kernel modules filelist/recipe; 
  - For the Linux kernel and kernel modules, use the
    sections_to_remove.txt/files_to_remove.txt filelist files to exclude
    kernel modules from the kernel modules filelist/recipe
    - `generate_recipe.sh -p linux-image-X.XX.XX-lack | grep -nf sections_to_remove.txt > linux-image-X.XX.XX-lack.txt` 
    - `generate_recipe.sh -p linux-image-X.XX.XX-lack | grep -nf sections_to_remove.txt | tee linux-image-X.XX.XX-lack.txt` 
    - `generate_recipe.sh -p linux-image-X.XX.XX-lack | grep -nf sections_to_remove.txt | grep -nf files_to_remove.txt | tee linux-image-X.XX.XX-lack.txt` 
    - `cat linux-image-X.XX.XX-lack.txt | grep -nf sections_to_remove.txt > linux-image-X.XX.XX-lack.txt` 
- run `make_initramfs.sh` to generate the initramfs file.  The following
  variables are exported:
  - `BUILD_BASE` - base directory for lack project
  - `PROJECT_DIR` - directory containing the project to build the initramfs file
    for; this could be the same as or different from BUILD_BASE
  - `TEMP_DIR` - temporary directory that's created to store filelists and
    temporary files needed to build the initramfs file
  - `FILELIST` - the name of the filelist that's created for the initramfs image
    (project files + recipe files), and also the name of the project's
    filelist (project files) '''TODO''' change the name of the project
    filelist to something else, so that there's no possibility for filename
    conflicts

Generating a kernel filelist:

    sh ~/src/lack-hg/scripts/generate_recipe.sh -p linux-image-2.6.34-lack \
    | grep -vf sections_to_remove.txt \
    | grep -vf files_to_remove.txt \
    | tee linux-image-2.6.34-lack.txt

vim: filetype=markdown shiftwidth=2 tabstop=2
