
# Usage of ram based building cache

Please read the WARNINGS before start using these scripts!

## WARNINGS

* These scripts are written to create/destroy/backup/check a ram based emporary directory, just like tmpfs, you MUST NOT store any important data in such created directory!

* If not explicitly backup the data stored in such temporary directory, the data will be LOST forever because the data are stored in memory!

* For data security issue, these scripts are protected and only allowed to run inside of Linux Lab.

* If you want the building targets/files are saved persistently, please NOT use this feature!

## Usage

Create a ram based temporary filesystem, mount it to `/labs/linux-lab/build` and compile linux kernel to it:

    $ sudo tools/build/cache
    $ make kernel

  The building targets/files will be stored in it temporarily and disapear after shutting down your machine!

Check the status of the mounted filesystem:

    $ sudo tools/build/free

Backup the data before shutting down your machine:

    $ sudo tools/build/backup

  If the target device has not enough space, please plugin an external device and backup it manually:

    $ dd if=/dev/zram0 of=/path/to/zram_backup_file bs=4M conv=notrunc,noerror status=progress
    or
    $ dd if=tmpfs/build.img of=/path/to/build_backup_file bs=4M conv=notrunc,noerror status=progress

umount or destroy the ram based filesystem explicitly before shutting down your machine:

    $ sudo tools/build/uncache
