 #!/usr/bin/env bash



{

l_smask='01000'

a_file=(); a_dir=() # Initialize arrays

a_path=(! -path "/run/user/*" -a ! -path "/proc/*" -a ! -path "*/containerd/*" -a ! -path "*/kubelet/pods/*" -a ! -path "*/kubelet/plugins/*" -a ! -path "/sys/*" -a ! -path "/snap/*")

while IFS= read -r l_mount; do

while IFS= read -r -d $'\0' l_file; do

if [ -e "$l_file" ]; then

l_mode="$(stat -Lc '%#a' "$l_file")"

if [ -f "$l_file" ]; then # Remove excess permissions from WW files

echo -e " - File: \"$l_file\" is mode: \"$l_mode\"\n - removing write permission on \"$l_file\" from \"other\""

chmod o-w "$l_file"

fi

if [ -d "$l_file" ]; then # Add sticky bit

if [ ! $(( $l_mode & $l_smask )) -gt 0 ]; then

echo -e " - Directory: \"$l_file\" is mode: \"$l_mode\" and doesn't have the sticky bit set\n - Adding the sticky bit"

chmod a+t "$l_file"

fi

fi

fi

done < <(find "$l_mount" -xdev \( "${a_path[@]}" \) \( -type f -o -type d \) -perm -0002 -print0 2> /dev/null)

done < <(findmnt -Dkerno fstype,target | awk '($1 !~ /^\s*(nfs|proc|smb|vfat|iso9660|efivarfs|selinuxfs)/ && $2 !~ /^(\/run\/user\/|\/tmp|\/var\/tmp)/){print $2}')

} 
