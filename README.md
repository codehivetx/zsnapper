# zsnapper - incremental zfs backups

Maybe it's not the best plan, but I'm making incremental backups of zfs datasets to removable USB storage.

## Usage

Currently the script has `TARGET=/mnt/backup` as the target disk. Fix this if it's not quite right.

Start your first backup..

```shell
$ bash zsnapper.sh tank/home
```

The script will create a snapshot of the form `tank/home@backup-9999-12-30` with today's date.
Then, it will make a backup to `/mnt/backup/tank/home/home@backup-9999-12-30`.

Come back and run it again tomorrow, and it will create an incremental backup to `/mnt/backup/tank/home/home@backup-9999-12-31` containing only the differences.

If you have multiple disks for `/mnt/backup` to swap in and out, it will check each one for the previous successful backup.  That is,  if `/mnt/backup` is a different disk and you re-run the script, it will build an incremental backup since the last time it was backed up to that disk.

## Notes

- non-recursive. Only backs up one dataset at a time.

## Bugs

Many. not enough error checking.

## License and credits

- available under [LICENSE](./LICENSE), Apache-2.0

- thanks to `@xai` in <https://xai.sh/2018/08/27/zfs-incremental-backups.html> for the idea

- Author: [Steven R. Loomis @srl295](https://github.com/srl295) of [@codehivetx](https://github.com/codehivetx)
