#!/bin/bash
#
# bash git prompt support
#
# Copyright (C) 2020 Wu Zhangjin <lzufalcon@163.com>
#
function _makefile_targets {
    local curr_arg;
    local targets;

    curr_arg=${COMP_WORDS[COMP_CWORD]}

    case $COMP_CWORD in
         2)
            if [[ -e "$(pwd)/Makefile" ]]; then
                common_targets="$(grep "^APP_TARGETS :=" $(pwd)/Makefile | cut -d '=' -f2)"
                echo $common_targets | tr ' ' '\n' | grep -q "^${COMP_WORDS[COMP_CWORD-1]}$"
                # FXIME: Not all of the packages support 'all'
                if [ $? -eq 0 ]; then
                  targets="all $(grep "^APPS :=" $(pwd)/Makefile | cut -d '=' -f2)"
                else
                  echo
                  echo "LOG: No such command matched: ${COMP_WORDS[COMP_CWORD-1]}"
                  return 0
                fi
            fi
            ;;
         *)
            # Find makefile targets available in the current directory
            ignores="^_|-km|features|kernel-modules|module-|module$|FORCE|rootdir|default-"
            if [[ -e "$(pwd)/Makefile" ]]; then
                common_targets="$(grep "^APP_TARGETS :=" $(pwd)/Makefile | cut -d '=' -f2)"
                all_apps="$(grep "^APPS :=" $(pwd)/Makefile | cut -d '=' -f2)"
                app_targets=''
                for app in $all_apps
                do
                    for target in $common_targets
                    do
                        app_targets="$app_targets $app-$target"
                    done
                done
                default_targets="$(egrep -e '^[a-zA-Z0-9_-]+:[^=]*' $(pwd)/Makefile | grep -v ":=" | cut -d ':' -f1 | egrep -v "$ignores" | tr '\n' ' ')"
                targets="$common_targets $all_apps $default_targets"
            fi
            ;;
    esac

    COMPREPLY=( $(compgen -W "${targets[@]}" -- $curr_arg ) );
}

complete -F _makefile_targets make
