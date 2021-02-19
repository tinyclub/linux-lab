#!/bin/bash
#
# bash git prompt support
#
# Copyright (C) 2021 Wu Zhangjin <falcon@ruma.tech>
#

# Allow commands with '='
COMP_WORDBREAKS="$(echo $COMP_WORDBREAKS | tr -d '=') "

function _makefile_targets {
    local curr_arg;
    local targets;

    if [ "$(pwd)" == "/labs/linux-lab" ]; then

    curr_arg=${COMP_WORDS[COMP_CWORD]}

    case $COMP_CWORD in
         2)
            if [[ -e "$(pwd)/Makefile" ]]; then
                last_arg=${COMP_WORDS[COMPCWORD-1]}
                common_targets="$(grep "^APP_TARGETS :=" $(pwd)/Makefile | cut -d '=' -f2)"
                echo $common_targets | tr ' ' '\n' | grep -q "^$last_arg$"

                # FXIME: Not all of the packages support 'all'
                if [ $? -eq 0 ]; then
                  targets="all $(grep "^APPS :=" $(pwd)/Makefile | cut -d '=' -f2)"
                else
                  echo
                  echo "LOG: No such command matched: "$last_arg""
                  return 0
                fi
            fi
            ;;
         *)
            # Find makefile targets available in the current directory
            ignores="^_|-km|features|kernel-modules|module-|module$|FORCE|rootdir|default-"
            if [[ -e "$(pwd)/Makefile" ]]; then
                BOARDS="$(find $(pwd)/boards/ -maxdepth 3 -name "Makefile" -exec egrep -H "^_BASE|^_PLUGIN" {} \; | tr -s '/' | egrep ".*" | sort -t':' -k2 | cut -d':' -f1 | egrep -v "/module" | sed -e "s%$(pwd)/boards/\(.*\)/Makefile%BOARD=\1%g")"
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
                targets="${boards} ${BOARDS} $common_targets $all_apps $default_targets"
            fi
            ;;
    esac

    COMPREPLY=( $(compgen -W "${targets[@]}" -- $curr_arg ) );

    fi # only trigger for /labs/linux-lab/ working directory
}

complete -F _makefile_targets make
