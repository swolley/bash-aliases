#most of this aliases are for arch linux

alias eos-update="command eos-update --nvidia --paru --descriptions"
#commented, I created a command because of gnome update extensions
#alias eos-check="/usr/bin/checkupdates && /usr/bin/paru -Qua"

alias ports='netstat -tulanp'

alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias .....="cd ../../../.."
alias ......="cd ../../../../.."

mount() {
	if [ $# -eq 0 ] || [ "$1" = "-l" ] || [ "$1" = "--show-labels" ]; then
		command mount | column -t
	else
		command mount "$@"
	fi
}

eos-search() {
	paru search "$@"
}

__pkgmgr() {
	local pkgmgr="$1"
	local action="$2"
	
	shift 2
	
	if [ "$action" = "search" ]; then
        command "$pkgmgr" -Ss "$@"
    elif [ "$action" = "update" ]; then
        command "$pkgmgr" -Su "$@"
    elif [ "$action" = "install" ]; then
        command "$pkgmgr" -S "$@"
    elif [ "$action" = "remove" ]; then
        command "$pkgmgr" -R "$@"
    elif [ "$action" = "info" ]; then
        command "$pkgmgr" -Si "$@"
    elif [ "$action" = "autoremove" ]; then
        __safe_autoremove "$pkgmgr" "$@"
    else
        command "$pkgmgr" "$@"
    fi
}

__safe_autoremove() {
	local pkgmgr="$1"
	shift
	
	echo "🔍 Checking for orphaned packages..."
	
	local orphans
	orphans=$(command "$pkgmgr" -Qtdq 2>/dev/null)
	
	echo "📋 Checking orphaned packages:"
	if [ -n "$orphans" ]; then
		echo "$orphans" | while read -r pkg; do
			if [ -n "$pkg" ]; then
				echo "  - $pkg"
			fi
		done
	fi
	
	local orphan_count
	orphan_count=$(echo "$orphans" | wc -l)
	
	if [ "$orphan_count" -eq 0 ] || [ -z "$orphans" ]; then
		echo "✅ No orphaned packages found."
		return 0
	fi
	
	echo ""
	echo "⚠️  WARNING: $orphan_count orphaned packages found."
	echo "💡 Suggestion: Check each package manually before removing it."
	echo ""
	
	echo "Available options:"
	echo "1) Remove ALL the orphaned packages (RISKY)"
	echo "2) Confirm orphaned packages removal one by one"
	echo "3) Show orphaned packages details"
	echo "4) Cancel"
	echo ""
	
	printf "Choose an option (1-4): "
	read choice
	
	case "$choice" in
		1)
			echo "⚠️  Removing ALL the orphaned packages, are you sure? (y/N): "
			read confirm
			if [[ "$confirm" =~ ^[YySs]$ ]]; then
				command "$pkgmgr" -Rns $(echo "$orphans" | tr '\n' ' ')
			else
				echo "❌ Operation cancelled."
			fi
			;;
		2)
			echo "🔍 Individual confirmation removal..."
			echo "$orphans" | while read -r pkg; do
				if [ -n "$pkg" ]; then
					echo ""
					echo "📦 Package: $pkg"
					command "$pkgmgr" -Si "$pkg" 2>/dev/null | head -10
					echo ""
					printf "Remove $pkg? (y/N): "
					read remove_pkg
					if [[ "$remove_pkg" =~ ^[YySs]$ ]]; then
						command "$pkgmgr" -Rns "$pkg"
					else
						echo "⏭️  Skipped: $pkg"
					fi
				fi
			done
			;;
		3)
			echo "📋 Orphaned packages details:"
			echo "$orphans" | while read -r pkg; do
				if [ -n "$pkg" ]; then
					echo ""
					echo "📦 $pkg"
					command "$pkgmgr" -Si "$pkg" 2>/dev/null
					echo "----------------------------------------"
				fi
			done
			;;
		4)
			echo "❌ Operation cancelled."
			;;
		*)
			echo "❌ Invalid option. Operation cancelled."
			;;
	esac
}

pacman() {
    __pkgmgr "pacman" "$1"
}

paru() {
    __pkgmgr "paru" "$1"
}

yay() {
    __pkgmgr "yay" "$1"
}

html() {
	local base_path="/srv/http"
    if [ -n "$1" ] && [ -d "$base_path/$1" ]; then
    		cd "$base_path/$1"
    else
        cd /srv/http
    fi
}
