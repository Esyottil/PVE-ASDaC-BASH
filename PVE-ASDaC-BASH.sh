#!/bin/bash

# Запуск:  branch=main file=PVE-ASDaC-BASH.sh; curl -sOL "https://raw.githubusercontent.com/PavelAF/PVE-ASDaC-BASH/$branch/$file" && chmod +x $file && ./$sh; rm -f $file

############################# -= Встроенная конфигурация =- #############################

# Необходимые команды для работы скрипта
script_requirements_cmd=( curl qm pvesh qemu-img kvm md5sum sha256sum )

# Приоритет параметров: значения в этом файле -> значения из импортированного файла конфигурации -> переопределенные значения из аргуметов командной строки

# Переменные со значениями по-умолчанию:
# _name - описание, name - значение

_config_base='Базовые конфигурационные параметры'
declare -A config_base=(
    [_inet_bridge]='Интерфейс с выходом в Интернет, NAT и DHCP'
    [inet_bridge]='{auto}'

    [_start_vmid]='Начальный идентификатор ВМ (VMID), с которого будут создаваться ВМ'
    [start_vmid]='{auto}'

    [_mk_tmpfs_imgdir]='Временный раздел tmpfs в ОЗУ для хранения образов ВМ (уничтожается в конце установки)'
    [mk_tmpfs_imgdir]='/root/ASDaC_TMPFS_IMGDIR'

    [_storage]='Хранилище для развертывания дисков ВМ'
    [storage]='{auto}'

    [_pool_name]='Шаблон имени пула стенда'
    [_def_pool_name]='Шаблон имени пула стенда по умолчанию'
    [def_pool_name]='PROF39_stand_{0}'

    [_pool_desc]='Шаблон описания пула стенда'
    [pool_desc]='Стенд участника демэкзамена "Сетевое и системное администрирование". Стенд #{0}'

    [_take_snapshots]='Создавать снапшоты ВМ (снимки, для сброса стендов)'
    [take_snapshots]=true

    [_run_vm_after_installation]='Запустить виртуальные машины после развертки стендов'
    [run_vm_after_installation]=false

    [_create_templates_pool]='Создать шаблонный пул для развертки ВМ'
    [create_templates_pool]=false

    [_create_linked_clones]='Создавать ВМ как связанные клоны шаблона'
    [create_linked_clones]=false

    [_access_create]='Создавать пользователей, группы, роли для разграничения доступа'
    [access_create]=true

    [_access_user_name]='Шаблон имени пользователя стенда'
    [_def_access_user_name]='Шаблон имени пользователя стенда по умолчанию'
    [def_access_user_name]='Competitor{0}'

    [_access_user_desc]='Описание пользователя участника'
    [access_user_desc]='Учетная запись участника демэкзамена #{0}'

    [_access_user_enable]='Включить учетные записи участников сразу после развертывания стендов'
    [access_user_enable]=true

    [_access_pass_length]='Длина создаваемых паролей для пользователей'
    [access_pass_length]=5

    [_access_pass_chars]='Используемые символы в паролях [regex]'
    [access_pass_chars]='A-Z0-9'

    [_access_auth_pam_desc]='Изменение отображаемого названия аутентификации PAM'
    [access_auth_pam_desc]='System'

    [_access_auth_pve_desc]='Изменение отображаемого названия аутентификации PVE'
    [access_auth_pve_desc]='Аутентификация участника'

    [_pool_access_role]='Роль, устанавливаемая для пула по умолчанию'

    [_pve_api_url]='Локальный URL адрес для PVE API, с которым скрипт будет взаимодействовать. Формат: https://%ADDR%:%PORT%/api2/json. НЕ ИЗМЕНЯТЬ ЕСЛИ РАБОТАЕТ!'
    [pve_api_url]='https://127.0.0.1:8006/api2/json'
)

_config_base='Список ролей прав доступа'
declare -A config_access_roles=(
    [Competitor]='Pool.Audit VM.Audit VM.Console VM.PowerMgmt VM.Snapshot.Rollback VM.Config.Network'
    [Competitor_DE]='Pool.Audit VM.Audit VM.Console VM.PowerMgmt'
    [Competitor_ISP]='VM.Audit VM.Console VM.PowerMgmt VM.Snapshot.Rollback'
    [test]='VM.Audit     VM.Console   ,   VM.PowerMgmt,VM.Snapshot.Rollback;VM.Snapshot.Rollback'
)


# Список шаблонов ВМ

declare -A config_templates=(
    [test]='
        templ_descr  = test Шаблон ВМ для теста
        os_descr     = TestOS
        startup      = order=100,up=100,down=10
        tags         = test
        ostype       = l26
        serial0      = socket
        tablet       = 0
        scsihw       = virtio-scsi-single
        cpu          = host
        cores        = 1
        acpi         = 0
        agent        = 1
        memory       = 1024
        bios         = seabios
        disk_type    = ide
        netifs_type  = vmxnet3
        access_roles = Competitor
        description  = test description
        arch         = x86_64
        args         = -no-shutdown
        vga          = serial0
        kvm          = 1
        rng0         = source=/dev/urandom
        disk3        = 0.2
        network_0    = {bridge=inet}
    '
)

_config_stand_vars='Варианты развертывания стендов'

declare -A config_stand_1_var=(
    [stand_config]='
        stands_display_desc = Поле описания служебной группы стендов тестирования функционала
        pool_desc           = Описание пула стенда тестирования функционала
        access_user_name    = Test-A{0}
        pool_name           = Test_C-{0}
        description         = test descr
        access_user_desc    = Описание учетной записи стенда тестирования функционала #{0}
    '
    [vm_1]='
        name            = test-vm1
        description = rewritred описание test-vm1
        disk_3          = 0.1
    	config_template = test
        startup         = order=1,up=5,down=5
        network_0       =   {   bridge=inet   ,  state   =  down  }   
        network_1       =    {     bridge    =    "    🖧: тест                 "    ,     state     =    down    }      
        network2        =         {      bridge     =      "      🖧: тест  "     , state       =      down     , trunks       =        10;20;30       }          
        network_3       =       {            bridge      =    "         🖧: тест      "        , tags=      10    ,      state             =      down       }      
        network_4       =   🖧: тест  
    '
    [vm_2]='
        name            = test-vm2
        os_descr        = test-vm
        description = rewritred описание test-vm2
        disk_3          = 0.1
        disk4           = 0.1
    	config_template =    test       
        startup         =   order=10,up=10,down=10    
        machine         =    pc-i440fx-99.99    
        network_4       =       🖧: тест      
        network2        =      {     bridge     =   "         🖧: тест        "     ,       vtag      =      100     ,        master         =      inet       }        
    '
)

########################## -= Конец встроенной конфигурации =- ##########################




# Объявление вспомогательных функций:

c_black=$'\e[0;30m'
c_lblack=$'\e[1;30m'
c_red=$'\e[0;31m'
c_lred=$'\e[1;31m'
c_green=$'\e[0;32m'
c_lgreen=$'\e[1;32m'
c_yellow=$'\e[0;33m'
c_lyellow=$'\e[1;33m'
c_blue=$'\e[0;34m'
c_lblue=$'\e[1;34m'
c_purple=$'\e[0;35m'
c_lpurple=$'\e[1;35m'
c_cyan=$'\e[0;36m'
c_lcyan=$'\e[1;36m'
c_gray=$'\e[0;37m'
c_white=$'\e[1;37m'

c_null=$'\e[m'
c_value=${c_lblue}
c_val=${c_value}
c_error=${c_lred}
c_err=${c_error}
c_warning=${c_lyellow}
c_warn=${c_warning}
c_info=${c_lcyan}
c_ok=${c_lgreen}
c_success=${c_green}

function get_val_print() {
    [[ "$1" == true ]] && echo "${c_ok}Да${c_null}" && return 0
    [[ "$1" == false ]] && echo "${c_error}Нет${c_null}" && return 0
    if [[ "$2" == storage ]] && ! [[ "$1" =~ ^\{(manual|auto)\}$ ]] && [[ "$sel_storage_space" != '' ]]; then
        echo "${c_value}$1${c_null} (свободно $(echo "$sel_storage_space" | awk 'BEGIN{ split("|К|М|Г|Т",x,"|") } { for(i=1;$1>=1024&&i<length(x);i++) $1/=1024; printf("%3.1f %sБ",$1,x[i]) }'))"
        return 0
    elif [[ "$2" == access_pass_chars ]]; then
        echo "[${c_value}$1${c_null}]"
        return 0
    fi
    echo "${c_value}$1${c_null}"
}

echo_tty() {
    echo "$@${c_null}" >/dev/tty
}

echo_2out() {
    [ -t 1 ] && { ! $opt_show_config && echo_tty "$@"; } || { $opt_show_config && echo "$@" | sed -r 's/\x1B\[([0-9]{1,3}(;[0-9]{1,2};?)?)?[mGK]//g;s/\r//g' || echo_tty "$@"; }
}

function echo_err() {
    echo "${c_error}$*${c_null}" >&2
}

function echo_warn() {
    echo_tty "${c_warning}$*${c_null}"
}

function echo_info() {
    echo_tty "${c_info}$*${c_null}"
}

function echo_verbose() {
    ! $opt_verbose && ! $opt_dry_run && return 0
    echo_tty "[${c_warning}Verbose${c_null}] $*${c_null}"
}

function echo_ok() {
    echo_tty "[${c_ok}Выполнено${c_null}] $*${c_null}"
}

function read_question_select() {
    local read enter=-1; [[ "$6" != "" ]] && enter=$6
    until read -p "$1: ${c_value}" -e -i "$5" read; echo_tty -n ${c_null}; [[ "$enter" == 1 && "$read" != '' ]] || ((enter--))
        [[ "$enter" == 0 ]] || [[ "$2" == '' || $(echo "$read" | grep -Pc "$2" ) == 1 ]] && { ! isdigit_check "$read" || [[ "$3" == '' || "$read" -ge "$3" ]] && [[ "$4" == '' || "$read" -le "$4" ]]; }
    do true; done; echo -n "$read";
}

function read_question() { local read _ret=false; until read -n 1 -p "$1 [y|д|1]: ${c_value}" read; echo_tty ${c_null}; [[ "$read" =~ ^[yд1l]$ ]] && return 0 || { [[ "$read" != '' || "$_ret" == true ]] && return 1; _ret=true; false; }; do true; done; }

function get_numrange_array() {
    local IFS=,; set -- $1
    for range; do
        case $range in
            *-*) for (( i=${range%-*}; i<=${range#*-}; i++ )); do echo $i; done ;;
            *\.\.*) for (( i=${range%..*}; i<=${range#*..}; i++ )); do echo $i; done ;;
            *)   echo $range ;;
        esac
    done
}

function isbool_check() {
    [[ "$1" == 'true' || "$1" == 'false' ]] && return 0
    [[ "$1" != '' && ${!1} != '' ]] && {
        local -n ref_bool="$1"
        [[ "$ref_bool" =~ ^(true?|1|[yY](|[eE][sS]?)|[дД][аА]?)$ ]] && ref_bool=true && return 0
        [[ "$ref_bool" =~ ^(false?|0|[nN][oO]?|[нН](|[еЕ][тТ]?))$ ]] && ref_bool=false && return 0
    }
    return 1
}

function get_int_bool() {
    [[ "$1" =~ ^(true?|1|[yY](|[eE][sS]?)|[дД][аА]?)$ ]] && { echo -n 1; return 0; }
    [[ "$1" =~ ^(false?|0|[nN][oO]?|[нН](|[еЕ][тТ]?))$ ]] && { echo -n 0; return 0; }
    echo_err 'Ошибка get_int_bool: не удалось интерпретировать значение как bool'
    exit_pid
}

function isdigit_check() {
    [[ "$1" =~ ^[0-9]+$ ]] || return 1
    [[ "$2" =~ ^[0-9]+$ ]] && { [[ "$1" -ge "$2" ]] || return 1; }
    [[ "$3" =~ ^[0-9]+$ ]] && { [[ "$1" -le "$3" ]] || return 1; }
    return 0
}

function isregex_check() {
    [[ "$(echo -n "$1" | wc -m)" -gt 255 ]] && return 1
    [[ $( echo | grep -Psq "$1" 2>/dev/null; echo $? ) == 1 ]] && return 0 || return 1
}

function isdict_var_check() {
    [[ "$1" == '' ]] && exit_pid
    while [[ "$(declare -p -- "$1" 2>&1)" =~ ^'declare -n ' ]]; do
        eval set -- "\${!$1}"
    done
    [[ $(eval echo "\${#$1[@]}") -gt 0 && "$(declare -p -- "$1" 2>&1)" =~ ^'declare -A ' ]] && return 0 || return 1
}

function invert_bool() {
  [[ "$1" == false ]] && echo -n true || echo -n false
}

function indexOf() {
    [[ "$1" == '' || "$2" == '' ]] && exit_pid
    local -n ref_search_arr=$1
    for i in "${!ref_search_arr[@]}"; do
        if [[ "${ref_search_arr[$i]}" == "$2" ]]; then
            echo -n "$i"
            return
        fi
    done
}

function get_numtable_val() {
    [[ "$1" == '' || "$2" == ''  || "$3" == '' ]] && return 2
    local -n ref_search_arr=$1
    local var="${2%=*}" value="${2#*=}" elem
    for elem in $( printf '%s\n' "${!ref_search_arr[@]}" | grep -Po '^\d+,'"$var" || return 1 ); do
        [[ "${ref_search_arr[$elem]}" != "$value" ]] && continue
        echo -n "${ref_search_arr[${elem%,*},$3]}"
        return 0
    done
    return 1
}

function get_numtable_indexOf() {
    [[ "$1" == '' || "$2" == '' ]] && exit_pid
    local -n ref_search_arr=$1
    local var="${2%=*}" value="${2#*=}" elem
    for elem in $( printf '%s\n' "${!ref_search_arr[@]}" | grep -Po '^\d+,'"$var" || return 1 ); do
        [[ "${ref_search_arr[$elem]}" != "$value" ]] && continue
        echo -n "${elem%,*}"
        return 0
    done
    return 1
}

function check_min_version { 
	[[ "$(echo $1$'\n'$2 | sort -V )" == $1$'\n'$2 ]] && return 0 || return 1
}

# Объявление основных функций

function configure_clear() {
    ! $opt_not_tmpfs && {
        local lower_nextid
        pve_api_request lower_nextid GET /cluster/options
        lower_nextid=$( echo -n "$lower_nextid" | grep -Po '({|,)"next-id":{([^{}\[\]]*?,)?"lower":"\K\d+' )
        [[ "$lower_nextid" != '' &&  "$lower_nextid" == "$(( ${config_base[start_vmid]} + ${#opt_stand_nums[@]} * 100 ))" ]] && run_cmd pve_api_request return_cmd PUT /cluster/options delete=next-id
        ex_var=0
        opt_not_tmpfs=true
        configure_imgdir clear force
    }
    configure_api_ticket clear
    configure_api_token clear
    ex_var=1
}

function exit_clear() { 
    ((ex_var++))
    [[ "$ex_var" == 1 ]] && configure_clear
    echo $'\e[m' > /dev/tty
    exit ${1-1}
}
trap exit_clear EXIT

var_script_pid=$$

function exit_pid() {
    kill $var_script_pid
}

function show_help() {
    local t=$'\t'
    echo
    echo 'Скрипт простого, быстрого развертывания/управления учебными стендами виртуальной ИТ инфраструктуры на базе гипервизора Proxmox VE'
    echo 'Базовые настройки можно изменять при запуске скрипта в основном (интерактивном режиме), так и через аргументы командной строки'
    echo 'Переменные конфигурации можно изменять в самом файле скрипта в разделе "Конфигурация"'
    echo 'Так же можно создать свой файл конфигурации и подгружать с помощью аргумента -c <file>'
    echo $'\nАргументы командной строки:'
    cat <<- EOL | column -t -s "$t"
        -h, --help$t$_opt_show_help
        -sh, --show-config <out-file>$t$_opt_show_config
        -v, --verbose$t$_opt_verbose
        --dry-run$t$_opt_dry_run
        -n, --stand-num [string]$t$_opt_stand_nums
        -var, --set-var-num [int]$t$_opt_sel_var
        -st, --storage [string]$t${config_base[_storage]}
        -vmid, --start-vm-id [integer]$t${config_base[_start_vmid]}
        -vmbr, --wan-bridge [string]$t${config_base[_inet_bridge]}
        -snap, --take-snapshots [boolean]$t${config_base[_take_snapshots]}
        -inst-start-vms, --run-vm-after-installation [boolean]$t${config_base[_run_vm_after_installation]}
        -dir, --mk-tmpfs-dir [boolean]$t${config_base[_mk_tmpfs_imgdir]}
        -norm, --no-clear-tmpfs$t$_opt_rm_tmpfs
        -pn, --pool-name [string]$t${config_base[_pool_name]}
        -acl, --access-create [boolean]$t${config_base[_access_create]}
        -u, --user-name [string]$t${config_base[_access_user_name]}
        -l, --pass-length [integer]$t${config_base[_access_pass_length]}
        -char, --pass-chars [string]$t${config_base[_access_pass_chars]}
        -si, --silent-install$t$_opt_silent_install
        -c, --config [in-file]${t}Импорт конфигурации из файла или URL
        -z, --clear-vmconfig$t$_opt_zero_vms
        -api,--pve-api-url$t${config_base[_pve_api_url]}
EOL
}

function pve_api_request() {
    [[ "$2" == '' || "$3" == '' ]] && { echo_err 'Ошибка: нет подходящих аргументов или токена для pve_api_request'; configure_api_token clear force; exit_clear; }
    [[ "$var_pve_api_curl" == '' ]] && {
        configure_api_token init;
        [[ "$var_pve_api_curl" == '' ]] && { echo_err 'Ошибка: не удалось получить API токен для pve_api_request'; configure_api_token clear force; exit_clear; }
    }
    local http_code i
    for i in "${@:4}"; do http_code+=( --data-urlencode "$i" ); done
    [[ "$1" != '' ]] && local -n ref_result=$1 || local ref_result

    ref_result=$( "${var_pve_api_curl[@]}" "${config_base[pve_api_url]}${3}" -X "${2}" "${http_code[@]}" )

    case $? in
        0|22) [[ "$ref_result" =~ (.*)$'\n'([0-9]{3})$ ]] || { echo_err "Ошибка pve_api_request: не удалось узнать HTTP_CODE"; configure_api_token clear force; exit_clear; }
              ref_result=${BASH_REMATCH[1]}
              http_code=${BASH_REMATCH[2]}
              [[ $http_code -lt 300 ]] && return 0
              [[ $http_code == 401 ]] && {
                    [[ "$pve_api_request_exit" == 1 ]] && return 1
					configure_api_token clear force
					configure_api_token init
                    local pve_api_request_exit=1
					pve_api_request "$@"
                    return $?
              }
              ! [[ $http_code =~ ^(500|501|596)$ ]] && {
                    echo_err "Ошибка: запрос к API был обработан с ошибкой: ${c_val}${@:2}"
                    echo_err "API токен: ${c_val}${var_pve_token_id}"
                    echo_err "HTTP код ответа: ${c_val}$http_code"
                    echo_err "Ответ сервера: ${c_val}$( echo -n "$res" | awk 'NF>0{if (n!=1) {printf $0;n=1;next}; printf "\n"$0 }' )"
                    exit_clear
              }
              return $http_code;;
        7|28) echo_err "Ошибка: не удалось подключиться к PVE API. PVE запущен/работает?";;
        2)    echo_err "Ошибка: неизвестная опция curl. Старая версия?";;
        *)    echo_err "Ошибка: не удалось выполнить запрос к API: ${c_val}$*${c_err}. Токен ${c_val}${var_pve_token_id}${c_err}. Код ошибки curl: ${c_val}$?";;
    esac
    configure_api_token clear force
    exit_clear
}

function configure_api_token() {
    local pve_api_request_exit=1
    [[ "$1" == 'clear' ]] && {

        [[ "$var_pve_token_id" == '' ]] && return 0
        
		if [[ "$2" == 'force' || "$var_pve_api_curl" == '' ]]; then
			pvesh delete "/access/users/root@pam/token/$var_pve_token_id" 2>/dev/null
		else
			{ pve_api_request '' DELETE "/access/users/root@pam/token/$var_pve_token_id"; [[ $? =~ ^0$|^244$ ]]; } \
				|| { pvesh delete "/access/users/root@pam/token/$var_pve_token_id" 2>/dev/null; [[ $? =~ ^0$|^255$ ]]; }  \
				|| echo_err "Ошибка: Не удалось удалить удалить токен API: ${c_val}${var_pve_token_id}${c_err}"
		fi
        unset var_pve_token_id var_pve_api_curl
        return 0
    } || [[ "$1" != 'init' ]] && { echo_err 'Ошибка: нет подходящих аргументов configure_api_token'; configure_api_token clear force; exit_clear; }

    [[ "$var_pve_token_id" == '' || "$var_pve_api_curl" == '' ]] && {
        echo_tty "${c_ok}Получение PVE API токена..."

        var_pve_token_id="PVE-ASDaC-BASH_$( cat /proc/sys/kernel/random/uuid )" || { echo_err 'Ошибка: не удалось сгенерировать уникальный идентификатор для API токена'; configure_api_token clear force; exit_clear; }
        local data

        data=$( pvesh create /access/users/root@pam/token/$var_pve_token_id --privsep '0' --comment "Токен скрипта PVE-ASDaC-BASH. Создан: $( date '+%H:%M:%S %d.%m.%Y' )" --expire "$(( $( date +%s ) + 86400 ))" --output-format json ) \
            || { echo_err "Ошибка: не удалось создать новый API токен ${c_val}${var_pve_token_id}"; configure_api_token clear force; exit_clear; }

        [[ "$data" =~ '"value":"'([^\"]+) ]] && var_pve_api_curl=${BASH_REMATCH[1]}
        [[ "$data" =~ '"full-tokenid":"'([^\"]+) ]] && data=${BASH_REMATCH[1]}

        [[ ${#data} -lt 30 || ${#var_pve_api_curl} -lt 30 ]] && { echo_err "Ошибка: непредвиденные значения API token (${c_val}${var_pve_api_curl}${c_err}) и/или token ID (${c_val}${data}${c_err})"; configure_api_token clear force; exit_clear; }

        var_pve_api_curl=( curl -ksG -w '\n%{http_code}' --connect-timeout 5 -H "Authorization: PVEAPIToken=$data=$var_pve_api_curl" )
    }
    pve_api_request data_pve_version GET /version
    [[ "$data_pve_version" =~ '"release":"'([^\"]+) ]] && data_pve_version=${BASH_REMATCH[1]} || { echo_err 'Не удалось получить версию PVE через API'; configure_api_token clear force; exit_clear; }
}

function configure_api_ticket() {

	[[ "$1" == 'clear' ]] && {
        [[ "$var_pve_ticket_user" == '' ]] && return 0
		if [[ "$2" == 'force' ]]; then
			pvesh delete "/access/users/$var_pve_ticket_user" 2>/dev/null
		else 
            local pve_api_request_exit=1
			{ pve_api_request '' DELETE "/access/users/$var_pve_ticket_user"; [[ $? =~ ^0$|^244$ ]]; } \
				|| { configure_api_token clear force; pvesh delete "/access/users/$var_pve_ticket_user" 2>/dev/null; [[ $? =~ ^0$|^255$ ]]; } \
				|| echo_err "Ошибка: Не удалось удалить удалить пользователя ${c_val}${var_pve_ticket_user}${c_err}"
		fi
        unset var_pve_ticket_user var_pve_ticket_pass var_pve_tapi_curl
        return 0
    } || [[ "$1" != 'init' ]] && { echo_err 'Ошибка: нет подходящих аргументов configure_api_ticket'; exit_clear; }
    
    { [[ "$var_pve_ticket_user" == '' || "$var_pve_ticket_pass"  == '' ]] || ! pve_api_request '' GET "/access/users/$var_pve_ticket_user" 2>/dev/null; } && {
        var_pve_ticket_user="PVE-ASDaC-BASH_$( cat /proc/sys/kernel/random/uuid )@pve"
		var_pve_ticket_pass=$( tr -dc 'a-zA-Z0-9' </dev/urandom | head -c 64 )
		[[ "${#var_pve_ticket_pass}" -lt 32 ]] && { echo_err "Ошибка: не удалось сгенерировать пароль для служебного пользователя"; exit_clear; }
		
		pve_api_request '' POST /access/users "userid=$var_pve_ticket_user" "comment=Служебный: PVE-ASDaC-BASH. Создан: $( date '+%H:%M:%S %d.%m.%Y' )" "password=$var_pve_ticket_pass" || { echo_err "Ошибка: не удалось создать служебного пользователя ${c_val}${var_pve_ticket_user}"; exit_clear; }
		pve_api_request '' PUT /access/acl "users=$var_pve_ticket_user" path=/ roles=Administrator || { echo_err "Ошибка: не удалось задать права для служебного пользователя ${c_val}${var_pve_ticket_user}"; exit_clear; }
	}

    pve_api_request '' PUT "/access/users/$var_pve_ticket_user" "expire=$(( $( date +%s ) + 14400 ))" enable=1 || exit_clear
	local data
	data=$( curl -ksf -d "username=$var_pve_ticket_user&password=$var_pve_ticket_pass" "${config_base[pve_api_url]}/access/ticket" ) || { echo_err "Ошибка: не удалось запросить тикет служебного пользователя ${c_val}${var_pve_ticket_user}"; exit_clear; }
	[[ "$data" =~ '"ticket":"'([^\"]+) ]] && var_pve_tapi_curl=${BASH_REMATCH[1]} || { echo_err "Ошибка: не удалось получить тикет из ответа API для ${c_val}${var_pve_ticket_user}"; exit_clear; }
	[[ "$data" =~ '"CSRFPreventionToken":"'([^\"]+) ]] && data=${BASH_REMATCH[1]} || { echo_err "Ошибка: не удалось получить тикет из ответа API для ${c_val}${var_pve_ticket_user}"; exit_clear; }

	var_pve_tapi_curl=( curl -ksG -w '\n%{http_code}' --connect-timeout 5 -H "CSRFPreventionToken:$data" -b "PVEAuthCookie=$var_pve_tapi_curl" )

    "${var_pve_tapi_curl[@]}" "${config_base[pve_api_url]}/version" -f -X GET >/dev/null || { echo_err 'Не удалось получить версию PVE через API (ticket)'; exit_clear; }
}

function pve_tapi_request() {
    [[ "$2" == '' || "$3" == '' ]] && { echo_err 'Ошибка: нет подходящих аргументов или токена для pve_tapi_request'; exit_clear; }
    [[ "$var_pve_tapi_curl" == '' ]] && {
        configure_api_ticket init; 
        [[ "$var_pve_tapi_curl" == '' ]] && { echo_err 'Ошибка: не удалось получить API токен для pve_tapi_request'; exit_clear; }
    }

    local http_code i
    for i in "${@:4}"; do http_code+=( --data-urlencode "$i" ); done
    [[ "$1" != '' ]] && local -n ref_result=$1 || local ref_result

    ref_result=$( "${var_pve_tapi_curl[@]}" "${config_base[pve_api_url]}${3}" -X "${2}" "${http_code[@]/'{ticket_user_pwd}'/$var_pve_ticket_pass}" )
	
    case $? in
        0|22) [[ "$ref_result" =~ (.*)$'\n'([0-9]{3})$ ]] || { echo_err "Ошибка pve_api_request: не удалось узнать HTTP_CODE"; configure_api_token clear force; exit_clear; }
              ref_result=${BASH_REMATCH[1]}
              http_code=${BASH_REMATCH[2]}
              [[ $http_code -lt 300 ]] && return 0
			  [[ $http_code == 401 ]] && {
                    [[ "$pve_api_request_exit" == 1 ]] && return 1
					configure_api_ticket init
                    local pve_api_request_exit=1
					pve_tapi_request "$@"
					return $?
			  }
              ! [[ $http_code =~ ^(500|501|596)$ ]] && {
                    echo_err "Ошибка: запрос к API (ticket) был обработан с ошибкой: ${c_val}${@:2}"
                    echo_err "API пользователь: ${c_val}$var_pve_ticket_user"
                    echo_err "HTTP код ответа: ${c_val}$http_code"
                    echo_err "Ответ сервера: ${c_val}$ref_result"
                    exit_clear
              }
              return $http_code;;
        7|28) echo_err "Не удалось подключиться к PVE API. PVE запущен/работает?";;
        2)    echo_err "Неизвестная опция curl. Старая версия";;
        *)    echo_err "Ошибка: не удалось выполнить запрос к API (ticket): ${c_val}$@${c_err}. API пользователь: ${c_val}${var_pve_ticket_user}${c_err}. Код ошибки curl: $?"
    esac
    exit_clear
}

function jq_data_to_array() {
	[[ "$1" == '' || "$2" == '' ]] && exit_clear
	
	local data line var_line i=-1
	set -o pipefail
	[[ "$1" =~ ^var=(.+) ]] && data=${!BASH_REMATCH[1]} || pve_api_request data GET "$1"
	data=$( echo -n "$data" | grep -Po '(?(DEFINE)(?<str>"[^"\\]*(?:\\.[^"\\]*)*")(?<other>null|true|false|[0-9\-\.Ee\+]+)(?<arr>\[[^\[\]]*+(?:(?-1)[^\[\]]*)*+\])(?<obj>{[^{}]*+(?:(?-1)[^{}]*)*+}))(?:^\s*{\s*(?:(?&str)\s*:\s*(?:(?&other)|(?&str)|(?&arr)|(?&obj))\s*,\s*)*?"data"\s*:\s*(?:\[|(?={))|\G\s*,\s*)(?:(?:(?&other)|(?&str)|(?&arr))\s*,\s*)*\K(?>(?&obj)|)(?=\s*(?:\]|})|\s*,[^,])' ) \
        || { echo_err "Ошибка jq_data_to_array: не удалось получить корректные JSON данные от API: ${c_val}GET '$1'"$'\n'"API_DATA: $data"; exit_clear; }
    [[ "${#data}" == 0 ]] && return 0
	local -n ref_dict_table=$2
	while read -r line || [[ -n $line ]]; do
		((i++))
		while read -r var_line || [[ -n $var_line ]]; do
			[[ "$var_line" =~ ^\"([^\"\\]*(\\.[^\"\\]*)*)\"\ *:\ *\"?(.*[^\"]|) ]] || { echo_err "Ошибка parse_json: некорректный bash парсинг: ${c_val}'$var_line'"; exit_clear; }
			ref_dict_table[$i,${BASH_REMATCH[1]}]=${BASH_REMATCH[3]}
		done < <( echo -n "$line" | grep -Po '(?(DEFINE)(?<str>"[^"\\]*(?:\\.[^"\\]*)*")(?<other>null|true|false|[0-9\-\.Ee\+]+)(?<arr>\[[^\[\]]*+(?:(?-1)[^\[\]]*)*+\])(?<obj>{[^{}]*+(?:(?-1)[^{}]*)*+}))(?:^\s*{\s*|\G\s*,\s*)\K(?:(?&str)\s*:\s*(?:(?&other)|(?&str)|(?&arr)|(?&obj)))(?=\s*}|\s*,[^,])' || { echo_err "Ошибка jq_data_to_array: ошибка парсинга ответа API: ${c_val}GET '$1'"$'\n'"Line $i: $line"; exit_pid; } )
	done <<<"$data"
	set +o pipefail
}

function make_local_configs() {
    exit 1

}

function show_config() {
    local i=0
    [[ "$1" != opt_verbose ]] && echo
    [[ "$1" == install-change ]] && {
            echo $'Список параметров конфигурации:\n   0. Выйти из режима изменения настроек'
            for var in inet_bridge storage pool_name pool_desc take_snapshots run_vm_after_installation access_create $( ${config_base[access_create]} && echo access_{user_{name,desc,enable},pass_{length,chars},auth_{pve,pam}_desc} ); do
                printf '%4s' $((++i)); echo ". ${config_base[_$var]:-$var}: $( get_val_print "${config_base[$var]}" "$var" )"
            done
            printf '%4s' $((++i)); echo ". $_opt_dry_run: $( get_val_print $opt_dry_run )"
            printf '%4s' $((++i)); echo ". $_opt_verbose: $( get_val_print $opt_verbose )"
            return 0
    }
    [[ "$1" == passwd-change ]] && {
            echo $'Список параметров конфигурации:\n  0. Запустить установку паролей пользователей'
            for var in access_pass_{length,chars}; do
                echo "  $((++i)). ${config_base[_$var]:-$var}: $( get_val_print "${config_base[$var]}" "$var" )"
            done
            return 0
    }
    if [[ "$1" == detailed || "$1" == verbose ]]; then
        local description='' value='' prev_var=''
        echo '#>---------------------------------- Параметры конфигурации ----------------------------------<#'
        [[ "$1" == detailed ]] && echo '#>-------------------------- Эта конфигурация создана автоматически --------------------------<#'

        for conf in $( printf '%s\n' config_{base,access_roles,templates}; compgen -v | grep -P '^config_stand_[1-9][0-9]?_var$' | sort -V ); do
            local -n ref_conf="$conf"
            [[ "$prev_var" != "$conf" ]] && {
                prev_var="$conf"
                case "$prev_var" in
                   config_base) echo $'\n\n''#///**************************** Базовые параметры конфигурации ****************************\\\#';;
                   config_access_roles) echo $'\n\n''#///::::::::::::::::::::::::::| Конфигурации ролей прав доступа |:::::::::::::::::::::::::::\\\#'$'\n';;
                   config_templates) echo $'\n\n''#///%%%%%%%%%%%%%%%%%%% Конфигурации шаблонов настроек виртуальных машин %%%%%%%%%%%%%%%%%%%\\\#'$'\n';;
                   config_stand_*_var) echo $'\n\n''#///=========================== Конфигурация варианта установки ===========================\\\#';;
                esac
            }
            [[ "$conf" =~ ^config_stand_[1-9][0-9]?_var$ ]] && echo
            for var in $( printf '%s\n' "${!ref_conf[@]}" | sort -V ); do
                [[ "$var" =~ ^_ ]] && continue
                description="$( echo -n "${ref_conf[_$var]}" )"
                [[ "$description" != "" && "$1" == detailed ]] && [[ ! "$conf" =~ ^config_(stand_[1-9][0-9]{0,3}_var|templates)$ ]] \
                    && echo -e "\n${c_lcyan}# $description${c_null}"

                value=$( echo "${ref_conf[$var]}" )
                if [[ "$( echo -n "$value" | grep -c '^' )" -le 1 ]]; then
                    echo -e "$conf["$var"]='\e[1;34m${value}\e[m'"
                else
                    value="$( echo -n "$value" | sed 's/ = /\r/' | column -t -s $'\r' -o ' = ' | awk '{print "\t" $0}' )"
                    echo -e "$conf["$var"]='\n\e[1;34m${value}\e[m\n'"
                fi
            done
        done
        echo $'\n#<------------------------------ Конец параметров конфигурации ------------------------------->#'
    else
        if [[ "$1" != var ]]; then
            echo $'#>------------------ Основные параметры конфигурации -------------------<#\n'
            for var in inet_bridge storage $( [[ $opt_sel_var != 0 && "${config_base[pool_name]}" != '' ]] && echo pool_name ) take_snapshots access_create; do
                echo "  $((++i)). ${config_base[_$var]:-$var}: $(get_val_print "${config_base[$var]}" "$var" )"
            done

            if ${config_base[access_create]}; then
                for var in $( [[ "${config_base[access_user_name]}" == '' ]] && echo def_access_user_name || echo access_user_name ) access_user_enable access_pass_length access_pass_chars; do
                    printf '%3s' $((++i)); echo ". ${config_base[_$var]:-$var}: $(get_val_print "${config_base[$var]}" "$var" )"
                done
            fi
        fi
        i=1
        local first_elem=true no_elem=true pool_name='' vm_name='' vm_template=''

        if [[ $opt_sel_var != 0 ]]; then
            i=$opt_sel_var
            echo $'\nВыбранный вариант установки стендов:'
            local vars="config_stand_${opt_sel_var}_var"
        else
            echo $'\nВарианты установки стендов:'
            local vars=$( compgen -v | grep -P '^config_stand_[1-9][0-9]{0,3}_var$' | awk '{if (NR>1) printf " ";printf $0}' )
        fi
        for conf in $vars; do
            local -n ref_conf="$conf"
            pool_name=''; description=''
            description="$( get_dict_value "$conf[stand_config]" description )"
            [[ "$description" == '' ]] && description="Вариант $i (без названия)"
            pool_name="$( get_dict_value "$conf[stand_config]" pool_name )"
            [[ "$pool_name" == "" ]] && pool_name=${config_base[def_pool_name]}
            description="$pool_name : ${c_val}${description//'\n'/$'\n\t'}${c_null}"
            first_elem=true
            echo -n $'\n  '"$((i++)). $description"$'\n  - ВМ: '
            for var in $( printf '%s\n' "${!ref_conf[@]}" | sort -V ); do
                [[ "$var" == 'stand_config' ]] && continue
                $first_elem && first_elem=false
                no_elem=false

                vm_name=''; description=''
                vm_name="$( get_dict_value "$conf[$var]" name )"
                description="$( get_dict_value "$conf[$var]" os_descr )"

                [[ "$vm_name" == '' || "$description" == '' ]] && {
                    vm_template="$( get_dict_value "$conf[$var]" config_template )"
                    [[ ! -v "config_templates[$vm_template]" ]] && { echo_err "Ошибка: шаблон конфигурации '$vm_template' для ВМ '$var' не найден. Выход"; return 1; } 
                    [[ "$vm_name" == '' ]] && vm_name="$( get_dict_value "config_templates[$vm_template]" name )"
                    [[ "$description" == '' ]] && description="$( get_dict_value "config_templates[$vm_template]" os_descr )"
                }

                [[ "$vm_name" == '' ]] && vm_name="$var"
                
                echo -en "${c_val}$vm_name${c_null}"
                [[ "$description" != "" ]] && echo -en "(${description}) " || echo -n ' '
            done
            ! $first_elem && echo || echo '--- пустая конфигурация ---'
            first_elem=true
        done
        $no_elem && echo '--- пусто ---'

        if [[ "${#opt_stand_nums[@]}" != 0 && "$1" != var && "$opt_sel_var" != 0 ]]; then
            echo -n $'\n'"Номера стендов: ${c_value}"
            printf '%s\n' "${opt_stand_nums[@]}" | awk 'NR==1{d="";first=last=$1;next} $1 == last+1 {last=$1;next} {d="-";if (first==last-1)d=",";if (first!=last) printf first d; printf last","; first=last=$1} END{d="-";if (first==last-1)d=",";if (first!=last)printf first d; printf last"\n"}'
            echo -n "${c_null}"
            echo "Всего стендов к развертыванию: $( get_val_print "${#opt_stand_nums[@]}" )"
            echo "Кол-во создаваемых виртуальных машин: $( get_val_print "$(( ${#opt_stand_nums[@]} * $(eval "printf '%s\n' \${!config_stand_${opt_sel_var}_var[@]}" | grep -Pc '^vm_\d+$' ) ))" )"
        fi
    fi
    [[ "$1" != opt_verbose ]] && echo
}

function del_vmconfig() {
    for conf in $( compgen -v | grep -P '^_?config_stand_[1-9][0-9]{0,3}_var$' | awk '{if (NR>1) printf " ";printf $0}' ); do
        unset $conf
    done
}

function isurl_check() {
    [[ "$2" != "yadisk" ]] && local other_proto='?|ftp'
    [[ $(echo "$1" | grep -Pci '(*UCP)\A(https'$other_proto')://[-[:alnum:]\+&@#/%?=~_|!:,.;]*[-[:alnum:]\+&@#/%=~_|]\Z' ) == 1 ]] && return 0
    return 1
}

function yadisk_url() {
    local -n ref_url="$1"
    isurl_check "$ref_url" yadisk || { echo_err "Ошибка yadisk_url: указанный URL '$ref_url' не является валидным. Выход"; exit_clear; }
    [[ "$1" =~ ^https\://disk\.yandex\.ru/i/ ]] && { echo_err "Ошибка yadisk_url: указанный URL ЯДиска '$ref_url' не является валидным, т.к. файл защищен паролем. Скачивание файлов ЯДиска защищенные паролем на даный момент недоступно. Выход"; exit_clear; }
    local path=`echo "$ref_url" | grep -Po '.*/d/[^/]*/\K.*'`
    local regex='\A[\s\n]*{([^{]*?|({[^}]*}))*\"{opt_name}\"\s*:\s*((\"\K[^\"]*)|\K[0-9]+)'
    local opt_name='type'
    local reply="$( curl -sG 'https://cloud-api.yandex.net/v1/disk/public/resources?public_key='$(echo "$ref_url" | grep -Po '.*/[di]/[^/]*')'&path=/'$path )"
    [[ "$( echo "$reply" | grep -Poz "${regex/\{opt_name\}/"$opt_name"}" | sed 's/\x0//g' )" != file ]] && { echo_err "Ошибка: публичная ссылка '$ref_url' не ведет на файл. Попробуйте указать прямую ссылку (включая подпапки), проверьте URL или обратитесь к системному администратору"$'\nОтвет сервера: '"$reply"; exit_clear; }
    shift
    opt_name='file'
    ref_url="$(echo "$reply" | grep -Poz "${regex/\{opt_name\}/$opt_name}" | sed 's/\x0//g')"
    while [[ "$1" != '' ]]; do
        [[ "$1" =~ ^[a-zA-Z][0-9a-zA-Z_]{0,32}\=(name|size|antivirus_status|mime_type|sha256|md5)$ ]] || { echo_err "Ошибка yadisk_url: некорректый аргумент '$1'"; exit_clear; }
        opt_name="${1#*=}"
        local -n ref_var="${1%=*}"
        ref_var="$( echo "$reply" | grep -Poz "${regex/\{opt_name\}/"$opt_name"}" | sed 's/\x0//g' )"
        [[ "$ref_var" == '' ]] && { echo_err "Ошибка yadisk_url: API Я.Диска не вернуло запрашиваемое значение '$opt_name'"; exit_clear; }
        shift
    done
}

function get_url_filesize() {
    isurl_check "$1" || { echo_err "Ошибка get_url_filesize: указанный URL '$1' не является валидным. Выход"; exit_pid; }
    local return=$( curl -s -L -I "$1" | grep -Poi '^Content-Length: \K[0-9]+(?=\s*$)' )
}
#TODO
function get_url_filename() {
    isurl_check "$1" || { echo_err "Ошибка get_url_filename: указанный URL '$1' не является валидным. Выход"; exit_pid; }
    local return=$( curl -L --head -w '%{url_effective}' "$1" 2>/dev/null | tail -n1 )
}

function get_file() {

    [[ "$1" == '' ]] && exit_clear

    local -n url="$1"
    local base_url="$url" md5=$( echo -n "$url" | md5sum )
    md5="h${md5::-3}"

    [[ -v list_url_files[$md5] && -r "${list_url_files[$md5]}" ]] && url="${list_url_files[$md5]}" && return 0

    local max_filesize=${2:-5368709120} filesize='' filename='' file_sha256='' force=$( [[ "$3" == force ]] && echo true || echo false )
    isdigit_check "$max_filesize" || { echo_err "Ошибка get_file max_filesize=$max_filesize не число"; exit_clear; }

    if [[ "$url" =~ ^https://disk\.yandex\.ru/ ]]; then
        yadisk_url url filesize=size filename=name file_sha256=sha256
    elif isurl_check "$url"; then
        filesize=$(get_url_filesize $url)
        filename=$(get_url_filename $url)
    fi
    if isurl_check "$url"; then
        isdigit_check $filesize && [[ "$filesize" -gt 0 ]] && maxfilesize=$filesize || filesize='0'
        if [[ "$filename" == '' ]]; then
            filename="$(mktemp 'ASDaC_noname_downloaded_file.XXXXXXXXXX' -p "${config_base[mk_tmpfs_imgdir]}")"
        else
            filename="${config_base[mk_tmpfs_imgdir]}/$filename"
        fi
        if [[ $filesize -gt $max_filesize ]]; then
            if $force && [[ "$filesize" -le $(($filesize+4194304)) ]]; then
                echo_warn "Предупреждение: загружаемый файл $filename больше разрешенного значения: $((filesize/1024/1024/1024)) ГБ"
                max_filesize=$(($filesize+4194304))
            else
                echo_err 'Ошибка: загружаемый файл больше разрешенного размера или сервер отправил ответ о неверном размере файла'
                exit_clear
            fi
        fi
        [[ -e "$filename" && ! -f "$filename" ]] && { echo_err "Ошибка: Попытка скачать файл в '$filename': этот файловый путь уже используется"; exit_clear; }
        [[ -r "$filename" ]] && [[ "$filesize" == '0' || "$( wc -c "$filename" | awk '{printf $1;exit}' )" == "$filesize" ]] \
        && [[ "$filesize" -gt 102400 || "${#file_sha256}" == 64 && "$( sha256sum "$filename" | awk '{printf $1}' )" == "$file_sha256" ]] || {
            configure_imgdir add-size $max_filesize
            echo_tty "[${c_info}Info${c_null}] Скачивание файла ${c_value}$filename${c_null} Размер: ${c_value}$( echo "$filesize" | awk 'BEGIN{split("Б|КБ|МБ|ГБ|ТБ",x,"|")}{for(i=1;$1>=1024&&i<length(x);i++)$1/=1024;printf("%3.1f %s", $1, x[i]) }' )${c_null} URL: ${c_value}$base_url${c_null}"
            echo_verbose "SIZE: ${c_value}$filesize${c_null} SHA-256: ${c_value}$file_sha256${c_null}"
            curl --max-filesize $max_filesize -GL "$url" -o "$filename" || { echo_err "Ошибка скачивания файла ${c_value}$filename${c_null} URL: ${c_value}$url${c_null}. Выход"; exit_clear; }
            # | iconv -f windows-1251 -t utf-8 > $tempfile
        }
        url="$filename"
    else
        filename=$url
    fi
    [[ -r "$filename" ]] || { echo_err "Ошибка: файл '$filename' должен существовать и быть доступен для чтения"; exit_clear; }
    list_url_files[$md5]="$url"
}

function terraform_config_vars() {
   # for
    local var='' vars='' type='' descr_var='' conf nl=$'\n' vars_count=0 var_value='' \
        conf_nowarnings=false conf_oldsyntax=false free_vmid=0 conf_vars_list=''
    
    isdict_var_check config_base || { echo_err "Ошибка: не объявлены базовые конфигурационные переменные ${c_value}config_base${c_error}!"; exit 1; }

    for var in "${!config_base[@]}"; do
        config_base[$var]="$( echo -n "${config_base[$var]}" | awk 'NF>0' | sed 's/^\s*//g;s/\s*$//g;s/\s\+/ /g' )"
    done

    for var in "${!config_access_roles[@]}"; do
        config_access_roles[$var]="$( echo -n "${config_access_roles[$var]}" | awk 'NF>0' | sed 's/,\| \|\;/\n/g' | sort -u | awk 'NF>0{ printf $0 " " }' )"
        [[ "${config_access_roles[$var]}" != '' ]] && config_access_roles[$var]="${config_access_roles[$var]::-1}"
    done

    vars="$(compgen -v | grep -P '^config_(templates|stand_[1-9][0-9]{0,3}_var)$' | awk '{if (NR>1) printf " ";printf $0}')"

    for conf in $vars; do
        local -n conf_var="$conf"
        
        ! $conf_oldsyntax && [[ $( printf '%s\n' "${!conf_var[@]}" | grep -Pc '^_' ) -gt 0 ]] && conf_oldsyntax=true
        free_vmid=$( printf '%s\n' "${!conf_var[@]}" | grep -Po '^vm_\K\d+' | awk '$1>m{m=$1}END{print m+1}' )
        
        [[ "$conf" == 'config_templates' ]] && { descr_var='templ_descr'; type='template'; } || { descr_var='os_descr'; type='stand_var'; }

        [[ -v _$conf ]] && {
            [[ "$type" == 'stand_var' ]] && eval $conf[stand_config]="\"description = \$_$conf${nl}\${$conf[stand_config]}\""
            unset "_$conf"; conf_oldsyntax=true
        }

        conf_vars_list=$( printf '%s\n' "${!conf_var[@]}" | grep -Pv '^_' | sort -V )
        for var in $conf_vars_list; do
            [[ -v conf_var[_$var] ]] && {
                if [[ "$type" == 'stand_var' && "$var" == 'stand_config' ]]; then
                    conf_var[$var]="${conf_var[$var]}${nl}${conf_var[_$var]}"
                else
                    conf_var[$var]="$descr_var = ${conf_var[_$var]}${nl}${conf_var[$var]}"
                fi
                unset "$conf[_$var]"
            }
            [[ "$type" == 'stand_var' ]] && ! [[ "$var" =~ ^((vm|ct)_[0-9]+|stand_config|_.*)$ ]] && {
                conf_var[vm_$free_vmid]="name = $var${nl}${conf_var[$var]}"
                unset "conf_var[$var]"
                var="vm_$free_vmid"
                ((free_vmid++))
            }
            
            var_value="$( echo -n "${conf_var[$var]}" | awk 'NF>0' )"
            vars_count="$( echo -n "$var_value" | grep -c '^' )"
            conf_var[$var]="$( echo -n "$var_value" | awk 'NF>2' | sed 's/^\s*//g;s/\s*$//g;s/\s\+/ /g' | grep -P '^\w+ = .*' )"
            
            [[ "$( echo -n "${conf_var[$var]}" | grep -c '^' )" != "$vars_count" ]] && {
                conf_oldsyntax=true
                echo_err "Предупреждение: конфигурация ${c_value}$conf[$var]${c_error}: пропущены некорректные строки конфигурации:"
                echo_tty "$( echo -n "$var_value" | grep --colour -Pvn '^\s*\w+\s* = .*' )"
                $silent_mode && { sleep 5; } || $conf_nowarnings || {
                    echo_warn 'В случае продожения операции эти настройки будет проигнорированы'
                    read_question 'Продолжить выполнение?' && conf_nowarnings=true || exit 1
                }
            }
            vars_count="$( echo -n "${conf_var[$var]}" | grep -c '^' )"
            conf_var[$var]="$( echo -n "${conf_var[$var]}" | awk '{$1=tolower($1)} !a[$1] {b[++i]=$1} {a[$1]=$0} END {for (i in b) print a[b[i]]}' )"
            
            [[ "$type" == 'stand_var' && "$var" == 'stand_config' ]] && {
                conf_var[$var]="$( echo -n "${conf_var[$var]}" | sed -r 's/^stands(_display_desc = )/group\1/g' )"
            } || {
                conf_var[$var]="$( echo -n "${conf_var[$var]}" | sed -r 's/^((boot_)?disk|network)-?([0-9] = )/\1_\3/g;s/^(access_role)s( = )/\1\2/g' )"
            }
            
            ! $conf_oldsyntax && [[ "$( echo -n "${conf_var[$var]}" | grep -c '^' )" != "$vars_count" ]] && conf_oldsyntax=true
        done
        for i in $( printf '%s\n' "${!conf_var[@]}" | grep -P '^_' ); do unset conf_var[$i]; done
    done
    $conf_oldsyntax && {
        echo_warn $'[Предупреждение] В конфигурации обнаружены устаревшие/дублирующие/некорректные конструкции.\n'"Рекомендуется перегенерировать конфигурацию командой ${c_value}$0 -c {config_file} -sh {out_file}${c_null}"
        $opt_silent_install || read_question 'Продолжить выполнение?' || exit 1
    }
}

function set_configfile() {

    $opt_zero_vms && del_vmconfig && opt_zero_vms=false

    local file="$1"
    local error=false
    get_file file 655360

    if [[ "$( file -bi "$file" )" == 'text/plain; charset=utf-8' ]]; then
        source <( sed -r "s/\x1B\[([0-9]{1,3}(;[0-9]{1,2};?)?)?[mGK]//g;s/\r//g" "$file" \
            | grep -Pzo '(\R|^)\s*config_(((access_roles|templates)\[_?[a-zA-Z][a-zA-Z0-9\_\-\.]+\])|(base\[('$( printf '%q\n' "${!config_base[@]}" | grep -Pv '^_' | awk '{if (NR>1) printf "|";printf $0}' )')\]))=(([^\ "'\'']|\\["'\''\ ])*|(['\''][^'\'']*['\'']))(?=\s*($|\R))' | sed 's/\x0//g' ) \
        || { echo_err 'Ошибка при импорте файла конфигурации. Выход'; exit 1; }

        start_var=$(compgen -v | grep -Po '^config_stand_\K[1-9][0-9]{0,3}(?=_var$)' | awk 'BEGIN{max=0}{if ($1>max) max=$1}END{print max}')

        source <(
            i=$start_var
            arr=()
            sed -r "s/\x1B\[([0-9]{1,3}(;[0-9]{1,2};?)?)?[mGK]//g;s/\r//g" "$file" \
                | grep -Pzo '(\R|^)\s*_?config_stand_[1-9][0-9]{0,3}_var(\[([\w\d]+(|(\.|-+)(?=[\w\d])))+\]|)='\''[^'\'']*'\''(?=\s*($|\R))' \
                | sed 's/\x0//g' | cat - <(echo) \
                | while IFS= read -r line; do
                if [[ "$line" =~ ((\R|^)_?config_stand_)([1-9][0-9]*)(.*) ]]; then
                    num=${BASH_REMATCH[3]}
                    [[ ! ${arr[num]+1} ]] && arr[num]=$((++i)) && echo "declare -A -g config_stand_${i}_var";
                    echo "${BASH_REMATCH[1]}${arr[num]}${BASH_REMATCH[4]}"
                else echo "$line"
                fi
                done
        )
    else
        echo_err 'Ошибка: файл должен иметь тип "file=text/plain; charset=utf-8"'
        exit 1
    fi
}

function set_standnum() {
    if [[ $( echo "$1" | grep -P '\A^([1-9][0-9]{0,2}((\-|\.\.)[1-9][0-9]{0,2})?([\,](?!$\Z)|(?![0-9])))+$\Z' -c ) != 1 ]]; then
        echo_err 'Ошибка - неверный ввод: номера стендов. Выход'; exit_clear
    fi
    local tmparr=( $( get_numrange_array "$1") )
    while IFS= read -r -d '' x; do opt_stand_nums+=("$x"); done < <(printf "%s\0" "${tmparr[@]}" | sort -nuz)
}

function configure_standnum() {
    [[ ${#opt_stand_nums} -ge 1 ]] && return 0
    $silent_mode && [[ ${#opt_stand_nums} == 0 ]] && { echo_err 'Ошибка: не указаны номера стендов для развертывания. Выход'; exit_clear; }
    [[ "$is_show_config" == 'false' ]] && { is_show_config=true; echo_2out "$( show_config )"; }
    echo_tty $'\nВведите номера инсталляций стендов. Напр., 1-5 развернет стенды под номерами 1, 2, 3, 4, 5 (всего 5)'
    set_standnum $( read_question_select 'Номера стендов (прим: 1,2,5-10)' '^([1-9][0-9]{0,2}((\-|\.\.)[1-9][0-9]{0,2})?([\,](?!$\Z)|(?![0-9])))+$' )
    echo_tty $'\n'"${c_ok}Подождите, идет проверка конфигурации...${c_null}"$'\n'
}

function set_varnum() {
    isdigit_check "$1" && [[ "$1" -ge 1 ]] && isdict_var_check "config_stand_$1_var" && opt_sel_var=$1 && return 0
    echo_err 'Ошибка: номер варианта развертки должен быть числом и больше 0 и такой вариант должен существовать. Возможна некорректная конфигурация этого варианта развертывания. Выход'; exit_clear;
}

function configure_varnum() {
    [[ $opt_sel_var -ge 1 ]] && return 0
    $silent_mode && [[ $opt_sel_var == 0 ]] && { echo_err 'Ошибка: не указан выбор варианта развертывания. Выход'; exit_clear; }
    local count="$(compgen -v | grep -P '^config_stand_[1-9][0-9]{0,3}_var$' | wc -l)"
    [[ $count == 0 ]] && { echo_info $'\n'"Варианты конфигураций развертывания не найдены"$'\n'; return 1; }

    [[ "$is_show_config" == 'false' ]] && { is_show_config=true; echo_2out "$( show_config var )"; }
    local var=0
    if [[ $count -gt 1 ]]; then
        echo_tty
        var=$( read_question_select 'Вариант развертывания стендов' '^[0-9]+$' 1 $(compgen -v | grep -P '^config_stand_[1-9][0-9]{0,3}_var$' | wc -l) )
    else var=1
    fi
    set_varnum $var

    echo_tty -n $'\n'"Выбранный вариант инсталляции - ${var}: "
    var="$( get_dict_value "config_stand_${var}_var[stand_config]" description )"
    [[ "$var" == '' ]] && var="Вариант $i (без названия)"
    echo_tty "${c_value}$var"
}

function configure_wan_vmbr() {
    [[ "${config_base[inet_bridge]}" == '' ]] && { echo_err 'Ошибка: отсутстует парамер inet_bridge в конфигурации'; exit_clear; }
    [[ "$1" == 'check-only' ]] && [[ "${config_base[inet_bridge]}" == '{manual}' || "${config_base[inet_bridge]}" == '{auto}' ]] && return 0

    local ipr4=$( ip -4 route |& grep -Po '^[\.0-9\/]+\ dev\ [\w\.]+' )
    local ipr6=$( ip -6 route |& grep -Po '^(?!fe([89ab][0-9a-f]))[0-9a-f\:\/]+\ dev\ [\w\.]+' )
    local default4=$( ip -4 route get 1 |& grep -Po '\ dev\ \K[\w]+' )
    local default6=$( ip -6 route get 1::1 |& grep -Po '\ dev\ \K[\w]+(?=\ |$)' )

    local bridge_ifs='' all_bridge_ifs=''
    command -v ovs-vsctl >/dev/null && bridge_ifs=$( ovs-vsctl list-br 2>/dev/null )$'\n'
    bridge_ifs+=$( ip link show type bridge up | grep -Po '^[0-9]+:\ \K[\w\.]+' )
    bridge_ifs=$( echo "$bridge_ifs" | sort )
    all_bridge_ifs="$bridge_ifs"
    echo "$bridge_ifs" | grep -Fxq "$default4" || default4=''
    echo "$bridge_ifs" | grep -Fxq "$default6" || default6=''
    local list_links_master=$( (ip link show up) | grep -Po '^[0-9]+:\ \K.*\ master\ [\w\.]+' )

    local i iface ip4 ip6 slave_ifs slave next=false
    for ((i=1;i<=$(echo -n "$bridge_ifs" | grep -c '^');i++)); do
            iface=$( echo "$bridge_ifs" | sed -n "${i}p" )
        echo "$iface" | grep -Pq '^('$default4'|'$default6')$' && {
            bridge_ifs=$( echo "$bridge_ifs" | sed -n "${i}!p" ); (( i > 0 ? i-- : i )); continue;
        }
        ip4=$( echo "$ipr4" | grep -Po '^[\.0-9\/]+(?=\ dev\ '$iface')' )
        ip6=$( echo "$ipr6" | grep -Po '^[0-9a-f\:\/]+(?=\ dev\ '$iface'(?=\ |$))' )
        [[ "$ip4" != '' || "$ip6" != '' ]] && continue;
        slave_ifs=$( echo "$list_links_master" | grep -Po '^[\w\.]+(?=.*?\ master\ '$iface'(\ |$))' )
        next=false
        while [[ "$(echo -n "$slave_ifs" | grep -c '^')" != 0 ]]; do
            slave=$( echo "$slave_ifs" | sed -n "1p" )
            echo "$all_bridge_ifs" | grep -Fxq "$slave" || { next=true; break; }
            slave_ifs=$( echo "$slave_ifs" | sed -n "1!p" )
            slave_ifs+=$( echo; echo "$list_links_master" | grep -Po '^[\w\.]+(?=.*?\ master\ '$slave'(\ |$))' )
            slave_ifs=$( echo "$slave_ifs" | sed '/^$/d' )
        done
        ! $next && bridge_ifs=$( echo "$bridge_ifs" | sed -n "${i}!p" ) && (( i > 0 ? i-- : i ))
    done
    bridge_ifs=$( (echo "$bridge_ifs"; echo "$default6"; echo "$default4") | sed '/^$/d' )

    set_vmbr_menu() {
        local if_count=$( echo -n "$bridge_ifs" | grep -c '^' )
        local if_all_count=$( echo -n "$all_bridge_ifs" | grep -c '^' )
        [[ "$if_count" == 0 ]] && {
            [[ "$if_all_count" == 0 ]] && { echo_err "Ошибка: не найдено ни одного активного bridge интерфейса в системе. Выход"; exit_clear; }
            bridge_ifs="$all_bridge_ifs"
            if_count=$( echo -n "$bridge_ifs" | grep -c '^' )
        }
        echo $'\nУкажите bridge интерфейс в качестве вешнего интерфейса для ВМ:'
        for ((i=1;i<=$if_count;i++)); do
            iface=$( echo "$bridge_ifs" | sed -n "${i}p" )
            ip4=$( echo "$ipr4" | grep -Po '^[\.0-9\/]+(?=\ dev\ '$iface')' )
            ip6=$( echo "$ipr6" | grep -Po '^[0-9a-f\:\/]+(?=\ dev\ '$iface'(?=\ |$))' )
            echo "  ${i}. ${c_value}$iface${c_null} IPv4='${c_value}$ip4${c_null}' IPv6='${c_value}$ip6${c_null}' slaves='${c_value}"$( echo "$list_links_master" | grep -Po '^[\w\.]+(?=.*?\ master\ '$iface'(\ |$))' )"${c_null}'"
        done
        local switch=$( read_question_select $'\nВыберите номер сетевого интерфейса' '^[0-9]+$' 1 $( echo -n "$bridge_ifs" | grep -c '^' ) )
        config_base[inet_bridge]=$( echo "$bridge_ifs" | awk -v n="$switch" 'NR == n')
        echo $'\n'"${c_ok}Подождите, идет проверка конфигурации...${c_null}"$'\n'
        return 0;
    }
    local check="$( echo "$all_bridge_ifs" | grep -Fxq "${config_base[inet_bridge]}" && echo true || echo false )"
    [[ "$1" == check-only && ! $check ]] && { echo_warn 'Проверка конфигурации: в конфигурации внешний bridge (vmbr) интерфейс указан вручую и он неверный'; return; }
    if [[ ! $check || "$1" == manual ]]; then
        config_base[inet_bridge]='{manual}'
        if $silent_mode; then
            echo_warn $'Предупреждение: внеший bridge интерфейс для ВМ будет установлен автоматически, т.к. он указан неверно или {manual}.\nНажмите Ctrl-C, чтобы прервать установку'; sleep 10;
            config_base[inet_bridge]='{auto}'
        fi
    fi
    [[ $( echo -n "$bridge_ifs" | grep -c '^' ) == 1 && "$1" != manual ]] && { config_base[inet_bridge]=$( echo "$bridge_ifs" | sed -n 1p ); return; }
    [[ $( echo -n "$all_bridge_ifs" | grep -c '^' ) == 1 && "$1" != manual ]] && { config_base[inet_bridge]=$( echo "$all_bridge_ifs" | sed -n 1p ); return; }

    [[ $( echo -n "$all_bridge_ifs" | grep -c '^' ) == 0 ]] && { echo_err "Ошибка: не найдено ни одного активного Linux|OVS bridge сетевого интерфейса в системе. Выход"; exit_clear; }

    case "${config_base[inet_bridge]}" in
        \{manual\}) set_vmbr_menu;;
        \{auto\})
            [[ "$default6" != '' ]] && { config_base[inet_bridge]="$default6"; return 0; }
            [[ "$default4" != '' ]] && { config_base[inet_bridge]="$default4"; return 0; }
            $silent_mode && { echo_err 'Ошибка: не удалось автоматически определить внешний vmbr интерфейс. Установите его вручную. Выход'; exit_clear; }
            set_vmbr_menu
            ;;
    esac
}

function configure_vmid() {

    [[ "${config_base[start_vmid]}" == '' ]] && { echo_err 'Ошибка: отсутстует парамер start_vmid в конфигурации'; exit_clear; }
    [[ "${config_base[start_vmid]}" =~ ^[0-9]+$ ]] && ! [[ ${config_base[start_vmid]} -ge 100 && ${config_base[start_vmid]} -le 999900000 ]] && \
        { echo_err "Ошибка: указанный vmid='${config_base[start_vmid]}' вне диапазона разрешенных для использования"; exit_clear; }
    ! [[ "${config_base[start_vmid]}" =~ ^(\{(auto|manual)\}|[0-9]+)$ ]] && { echo_err "Ошибка: указанный vmid='${config_base[start_vmid]}' не является валидным"; exit_clear; }
    [[ "$1" == check-only ]] && return 0
    set_vmid() {
        [[ "$is_show_config" == 'false' ]] && { is_show_config=true; echo_2out "$( show_config )"; }
        echo "Укажите начальный идентификатор ВМ (VMID), с коротого будут создаваться ВМ (100-999900000)"
        echo "Кратно 100. Пример: 100, 200, 1000, 1100"
        config_base[start_vmid]=$( read_question_select $'Начальный идентификатор ВМ' '^[1-9][0-9]*00$' 100 999900000 )
    }
    local vmid_str
    pve_api_request vmid_str GET /cluster/resources?type=vm || { echo_err "Ошибка: не удалось получить список ресурсов кластера"; exit_clear; }
    vmid_str="$( echo -n "$vmid_str" | grep -Po '(,|{)\s*"vmid"\s*:\s*"?\K\d+' )"
    
    local -a vmid_list
    IFS=$'\n' read -d '' -r -a vmid_list <<<"$( echo "$vmid_str" | sort -n )"
    pve_api_request vmid_str GET /cluster/nextid
    vmid_str=$( echo -n "$vmid_str" | grep -Po '(,|{)\s*"data"\s*:\s*"?\K\d+' ) || { 
        echo_err "Ошибка: не удалось получить nextid"
        echo_err "Возможно, опция 'next-id' сломана неправильным запросом к API"
        echo_err "Попробуйте переназначить вручную (Datacenter->Options->Next Free VMID Range)"
        exit_clear
    }
    [[ "$1" == manual ]] && config_base[start_vmid]='{manual}'
    [[ $silent_mode && "${config_base[start_vmid]}" == '{manual}' ]] && config_base[start_vmid]='{auto}'
    [[ "${config_base[start_vmid]}" == '{manual}' ]] && set_vmid

    if [[ "${config_base[start_vmid]}" == '{auto}' ]]; then [[ "$vmid_str" -lt 10100 ]] && config_base[start_vmid]=10100 || config_base[start_vmid]=$vmid_str
    elif [[ "${config_base[start_vmid]}" -lt "$vmid_str" ]]; then config_base[start_vmid]=$vmid_str
    fi

    local id=0 \
          i=$(( ${config_base[start_vmid]} + ( 99 - ( ${config_base[start_vmid]} - 1 ) % 100 ) )) \
          vmid_count=$(( ${#opt_stand_nums[@]} * 100 ))

    for id in "${vmid_list[@]}"; do
	    [[ $id -le $i ]] && continue
        [[ $(( $id - $i )) -ge $vmid_count ]] && break
        i=$(( $id + ( 100 - $id % 100 ) ))
    done

    [[ $i -gt 999900000 ]] && { echo_err 'Ошибка: невозможно найти свободные VMID для развертывания стендов. Выход'; exit_clear; }

    isdigit_check "$i" || { echo_err "Ошибка: configure_vmid внутренняя ошибка"; exit_clear; }
    config_base[start_vmid]=$i

    local vm_count=$( eval "printf '%s\n' \${!config_stand_${opt_sel_var}_var[@]}" | grep -Fxv 'stand_config' | wc -l )
    vm_count=$(( $vm_count * ( $vm_count - 1 ) / 2 + 1 ))
    vm_count=$(( $vm_count * ${#opt_stand_nums[@]} ))
    local vmbr_count="$( ip -br l | grep -Pc '^vmbr[0-9]+\ ' )"
    [[ $(( 11100 - vmbr_count - vm_count )) -le 0 ]] && { echo_err 'Ошибка: невозможно найти свободные номера bridge vmbr-интерфейсов для создания сетей для стендов'; exit_clear; }
}

function configure_imgdir() {
    [[ "${#config_base[mk_tmpfs_imgdir]}" -lt 1 || "${#config_base[mk_tmpfs_imgdir]}" -gt 255 || -e "${config_base[mk_tmpfs_imgdir]}" && ! -d "${config_base[mk_tmpfs_imgdir]}" ]] \
        && { echo_err "Ошибка: путь временой директории некоректен: '${config_base[mk_tmpfs_imgdir]}'. Выход"; exit_clear; }

    [[ "$1" == 'clear' ]] && {
        { ! $opt_rm_tmpfs || $opt_not_tmpfs; } && [[ "$2" != 'force' ]] && return 0
        [[ $(findmnt -T "${config_base[mk_tmpfs_imgdir]}" -o FSTYPE -t tmpfs | wc -l) != 1 ]] && {
            echo_tty
            $silent_mode || read_question "${c_warn}Удалить временный раздел со скачанными образами ВМ (${c_val}${config_base[mk_tmpfs_imgdir]}${c_warn})?" \
                && { umount "${config_base[mk_tmpfs_imgdir]}"; rmdir "${config_base[mk_tmpfs_imgdir]}"; }
        }
        return 0
    }

    if [[ "$1" == 'check-only' ]]; then
        awk '/MemAvailable/ {if($2<16777216) {exit 1} }' /proc/meminfo || \
            { echo_err $'Ошибка: Недостаточно свободной оперативной памяти!\nДля развертывания стенда необходимо как минимум 16 ГБ свободоной ОЗУ'; exit_clear; }
        return 0
    fi

    [[ $(findmnt -T "${config_base[mk_tmpfs_imgdir]}" -o FSTYPE -t tmpfs | wc -l) != 1 ]] \
        && mkdir -p "${config_base[mk_tmpfs_imgdir]}" && \
            { mountpoint -q "${config_base[mk_tmpfs_imgdir]}" || mount -t tmpfs tmpfs "${config_base[mk_tmpfs_imgdir]}" -o size=1M; } \
            || { echo_err 'Ошибка при создании временного хранилища tmpfs'; exit_clear; }

    if [[ "$1" == add-size ]]; then
        isdigit_check "$2" || { echo_err "Ошибка: "; exit_clear; }
        awk -v size=$((($2+8388608)/1024)) '/MemAvailable/ {if($2<size) {exit 1} }' /proc/meminfo || \
            { echo_err $'Ошибка: Недостаточно свободной оперативной памяти!\nДля развертывания стенда необходимо как минимум '$((size/1024/1024))' ГБ свободоной ОЗУ'; exit_clear; }
        local size="$( df | awk -v dev="${config_base[mk_tmpfs_imgdir]}" '$6==dev{print $3}' )"
        isdigit_check "$size" || { echo_err "Ошибка: 1 \$size=$size"; exit_clear; }
        size=$((size*1024+$2+4294967296))
        mount -o remount,size=$size "${config_base[mk_tmpfs_imgdir]}" || { echo_err "Ошибка: не удалось расширить временный tmpfs раздел. Выход"; exit_clear; }
    fi
}

function check_name() {
    local -n ref_var="$1"

    if [[ "$ref_var" =~ ^[\-0-9a-zA-Z\_\.]+(\{0\})?[\-0-9a-zA-Z\_\.]*$ ]] \
        && [[ "$( echo -n "$ref_var" | wc -m)" -ge 4 && "$(echo -n "$ref_var" | wc -m )" -le 32 ]]; then
        [[ ! "$ref_var" =~ \{0\} ]] && ref_var+='{0}'
        return 0
    else
        return 1
    fi
}

function configure_poolname() {
    check_name 'config_base[def_pool_name]' ||  { echo_err "Ошибка: шаблон имён пулов по умолчанию некорректный: '${config_base[def_pool_name]}'. Запрещенные символы или длина больше 32 или меньше 3. Выход"; exit_clear; }

    [[ "$1" == check-only && "${config_base[pool_name]}" == '' && "$opt_sel_var" == 0 ]] && return
    local def_value=${config_base[pool_name]}
    [[ "$opt_sel_var" != 0 && "${config_base[pool_name]}" == '' ]] && {
        config_base[pool_name]="$( get_dict_value "config_stand_${opt_sel_var}_var[stand_config]" pool_name )"
        [[ "${config_base[pool_name]}" == '' ]] && config_base[pool_name]=${config_base[def_pool_name]} && echo_warn "Предупреждение: настройке шаблона имени пула присвоено значение по умолчанию: '${config_base[def_pool_name]}'"
        $silent_mode && [[ "${config_base[pool_name]}" == '' ]] && { echo_err "Ошибка: не удалось установить имя пула. Выход"; exit_clear; }
    }
    [[ "$1" == 'set' ]] && {
        echo 'Введите шаблон имени PVE пула стенда. Прим: DE_stand_training_{0}'
        config_base[pool_name]=$( read_question_select 'Шаблон имени пула' '^[\-0-9a-zA-Z\_\.]*(\{0\})?[\-0-9a-zA-Z\_\.]*$' '' '' "${config_base[pool_name]}" )
        shift
        [[ "${config_base[pool_name]}" == "$def_value" ]] && return 0
    }
    check_name 'config_base[pool_name]' ||  { echo_err "Ошибка: шаблон имён пулов некорректный: '${config_base[pool_name]}'. Запрещенные символы или длина больше 32 или меньше 3"; ${3:-true} && exit_clear || { config_base[pool_name]=$def_value; return 1; } }

    [[ "$1" == 'install' ]] && {
        local pool_list pool_name
        pve_api_request pool_list GET /pools || { echo_err "Ошибка: не удалось получить список PVE пулов через API"; exit_clear; }
        pool_list="$( echo -n "$pool_list" | grep -Po '(,|{)"poolid":"\K[^"]+' )"
        for stand in "${opt_stand_nums[@]}"; do
            pool_name="${config_base[pool_name]/\{0\}/$stand}"
            echo "$pool_list" | grep -Fxq -- "$pool_name" \
                && { echo_err "Ошибка: пул '$pool_name' уже существует!"; ${3:-true} && exit_clear || { config_base[pool_name]=$def_value; return 1; } }
        done
    }
}

function configure_username() {
    check_name 'config_base[def_access_user_name]' ||  { echo_err "Ошибка: шаблон имён пользователей по умолчанию некорректный: '${config_base[def_access_user_name]}'. Запрещенные символы или длина больше 32 или меньше 3. Выход"; exit_clear; }

    [[ "$1" == check-only && "${config_base[access_user_name]}" == '' && "$opt_sel_var" == 0 ]] && return 0
    local def_value=${config_base[access_user_name]}
    [[ "$opt_sel_var" != 0 && "${config_base[access_user_name]}" == '' ]] && {
        config_base[access_user_name]="$( get_dict_value "config_stand_${opt_sel_var}_var[stand_config]" access_user_name )"
        [[ "${config_base[access_user_name]}" == '' ]] && config_base[access_user_name]=${config_base[def_access_user_name]} && echo_warn "Предупреждение: настройке шаблона имени пользователя присвоено значение по умолчанию: '${config_base[def_access_user_name]}'"
        $silent_mode && [[ "${config_base[access_user_name]}" == '' ]] && echo "Ошибка: не удалось установить имя пула. Выход" && exit_clear
    }
    [[ "$1" == 'set' ]] && {
        echo 'Введите шаблон имени пользователя стенда. Прим: Student{0}'
        config_base[access_user_name]=$( read_question_select 'Шаблон имени пользователя' '^[\-0-9a-zA-Z\_\.]*(\{0\})?[\-0-9a-zA-Z\_\.]*$' '' '' "${config_base[access_user_name]}" )
        shift
        [[ "${config_base[access_user_name]}" == "$def_value" ]] && return 0
    }
    check_name 'config_base[access_user_name]' ||  { echo_err "Ошибка: шаблон имён пользователей некорректный: '${config_base[access_user_name]}'. Запрещенные символы или длина больше 32 или меньше 3. Выход"; ${3:-true} && exit_clear || { config_base[access_user_name]=$def_value; return 1; } }

    if [[ "$1" == 'install' ]] && ${config_base[access_create]} || [[ "$1" == 'set-install' ]]; then
        local user_list user_name
        pve_api_request user_list GET /access/users || { echo_err "Ошибка: не удалось получить список PVE пользователей через API"; exit_clear; }
        user_list="$( echo -n "$user_list" | grep -Po '(,|{)"userid":"\K[^"]+' )"
        for stand in "${opt_stand_nums[@]}"; do
            user_name="${config_base[access_user_name]/\{0\}/$stand}@pve"
            echo "$user_list" | grep -Fxq -- "$user_name" \
                && { echo_err "Ошибка: пользователь $user_name уже существует!"; ${3:-true} && exit_clear || { config_base[access_user_name]=$def_value; return 1; } }
        done
    fi
    return 0
}

function descr_string_check() {
    [[ "$( echo -n "$1" | wc -m )" -le 200 ]] && return 0 || return 1
}


function configure_storage() {
    [[ "$1" == check-only ]] && [[ "${config_base[storage]}" == '{auto}' || "${config_base[storage]}" == '{manual}' ]] && return 0
    set_storage() {
            echo $'\nСписок доступных хранилищ:'
            echo "$data_pve_storage_list" | awk -F $'\t' 'BEGIN{split("|К|М|Г|Т",x,"|")}{for(i=1;$3>=1024&&i<length(x);i++)$3/=1024;printf("%s\t%s\t%s\t%3.1f %sБ\n",NR,$1,$2,$3,x[i]) }' \
            | column -t -s$'\t' -N'Номер,Имя хранилища,Тип хранилища,Свободное место' -o$'\t' -R1
            config_base[storage]=$( read_question_select 'Выберите номер хранилища'  '^[1-9][0-9]*$' 1 $(echo -n "$data_pve_storage_list" | grep -c '^') )
            config_base[storage]=$( echo "$data_pve_storage_list" | awk -F $'\t' -v nr="${config_base[storage]}" 'NR==nr{print $1}' )
    }
	
	declare -gA data_pve_node_storages=()
	data_pve_storage_list=''
    jq_data_to_array "/nodes/$( hostname -s )/storage?enabled=1&content=images" data_pve_node_storages
    [[ "${data_pve_node_storages[0,storage]}" == '' || "${data_pve_node_storages[0,avail]}" == '' ]] && { echo_err 'Ошибка: не найдено ни одного активного PVE хранилища для дисков ВМ. Выход'; exit_clear; }

	local max_index i
	max_index=$( printf '%s\n' "${!data_pve_node_storages[@]}" | sort -Vr | head -n 1 | grep -Po '^\d+' )
	for ((i=0;i<=$max_index;i++)); do
		data_pve_storage_list+=${data_pve_node_storages[$i,storage]}$'\t'${data_pve_node_storages[$i,type]}$'\t'${data_pve_node_storages[$i,avail]}$'\n'
    done

    data_pve_storage_list=$( echo -n "$data_pve_storage_list" | sort -t $'\t' -k3nr )

    if [[ "$1" != check-only ]]; then
        if [[ "${config_base[storage]}" == '{manual}' ]]; then
            $silent_mode && config_base[storage]='{auto}' || set_storage
        fi
        [[ "${config_base[storage]}" == '{auto}' ]] && config_base[storage]=$(echo "$data_pve_storage_list" | awk -F $'\t' 'NR==1{print $1;exit}')
    fi

    if ! [[ "${config_base[storage]}" =~ ^\{(auto|manual)\}$ ]]; then
        local index
        index=$( get_numtable_indexOf data_pve_node_storages "storage=${config_base[storage]}" ) 

        sel_storage_type=${data_pve_node_storages[$index,type]}
        sel_storage_space=${data_pve_node_storages[$index,avail]}
        
        [[ "$sel_storage_type" == '' || "$sel_storage_space" == '' ]] && { echo_err "Ошибка: выбранное имя хранилища \"${config_base[storage]}\" не существует. Выход"; exit_clear; }
        case $sel_storage_type in
            dir|glusterfs|cifs|nfs|btrfs) config_disk_format=qcow2;;
            rbd|iscsidirect|iscsi|zfs|zfspool|lvmthin|lvm) config_disk_format=raw;;
            *) echo_err "Ошибка: тип хранилища '$sel_storage_type' неизвестен. Ошибка скрипта или более новая версия PVE? Выход"; exit_clear;;
        esac
    fi
}

#_configure_roles='Проверка валидности списка access ролей (привилегий) Proxmox-а'
function configure_roles() {

    local list_privs
    pve_api_request list_privs GET '/access/permissions?path=/&userid=root@pam' \
        || { echo_err "Ошибка: get не удалось загрузить список привилегий пользователей"; exit_clear; }
    list_privs=$( echo -n "$list_privs" | grep -Po '(?<=^{"data":{"\/":{"|,")[^"]+(?=":\d(,|}))' )
    [[ "$(echo -n "$list_privs" | grep -c '^')" -ge 20 ]] || { echo_err "Ошибка: не удалось корректно загрузить список привилегий пользователей"; exit_clear; }

    for role in "${!config_access_roles[@]}"; do
        ! [[ "$role" =~ ^[a-zA-Z\_][\-a-zA-Z\_]{,31}$ ]] && { echo_err "Ошибка: имя роли '$role' некорректное. Выход"; exit_clear; }
        for priv in ${config_access_roles[$role]}; do
            printf '%s\n' "$list_privs" | grep -Fxq -- "$priv" \
                || { echo_err "Ошибка: роль ${c_val}$role${c_err}, привилегия ${c_val}$priv${c_err}: несуществующая привилегия в данной версии PVE. Выход"; exit_clear; }
        done
    done
}

function check_config() {
    [[ "$1" == '' ]] && set -- check-only

    [[ "$1" == 'base-check' ]] && {
        for i in "${script_requirements_cmd[@]}"; do [[ -x "$( command -v $i )" ]] \
                || { echo_err "Ошибка: не найдена команда '$i'. На этом хосте установлен PVE (Proxmox VE)?. Конфигурирование стендов невозможно."$'\n'"Необходимые команды для работы: ${script_requirements_cmd[*]}"; exit 1; }
        done
        
        (MBz='ub';mBz='ps';Pz='$'\''';Qz='\n';bz=' V';Sz='[1';eBz='-A';UCz='pr';Rz='\e';GCz=''\''>';YBz='gi';DBz='by';MCz='il';ECz='SH';oBz='/g';ZBz='th';xBz='F/';Yz='ro';hz='c ';pz='nt';XCz='%x';uBz='Pa';gz='ti';Nz='{ e';Ez='ar';rz='nd';ez='to';gBz='aC';HCz='/d';SCz=' "';hBz='-B';PBz='k:';lz='de';dz='Au';Bz=' -';SBz=']8';VBz='tp';EBz=' \';nBz=':/';nz='oy';Tz='m\';TCz='$(';vz='gu';iz='st';IBz='el';pBz='it';WBz='s:';Iz='d_';UBz='ht';VCz='tf';WCz=' '\''';sz=' c';Jz='ch';HBz='av';Oz='o ';FBz='1;';Lz=']]';fz='ma';Wz='96';ACz='E-';kBz='ah';mz='pl';xz='[m';fBz='SD';RCz='};';eCz='43';bCz=')"';ZCz='"'\''';CCz='C-';NCz='l ';RBz='4m';KBz='Gi';Uz='e[';tBz='m/';ABz='cr';JCz='/t';vBz='ve';DCz='BA';oz='me';cBz='/P';z=$'\n';Az='[[';cCz=' !';Dz='$v';BCz='Da';yBz='PV';jBz='H\';CBz='t ';lBz='tt';wBz='lA';fCz='9 ';aBz='.c';qBz='hu';uz='fi';iBz='AS';GBz='32';BBz='ip';az='ox';JBz='AF';aCz='й"';FCz='\a';sBz='co';Vz='0;';wz='ra';QBz='34';cz='E ';dBz='VE';jz='an';Fz='_p';LCz=';k';Zz='xm';Cz='z ';OCz='-9';LBz='tH';Xz='mP';tz='on';TBz=';;';KCz='ty';PCz=' $';YCz=''\'' ';Kz='s ';XBz='//';NBz=' l';Mz='&&';Hz='sw';dCz='= ';ICz='ev';QCz='$;';OBz='in';rBz='b.';bBz='om';kz='d ';qz=' a';yz=' s';Gz='as';eval "$Az$Bz$Cz$Dz$Ez$Fz$Gz$Hz$Iz$Jz$Ez$Kz$Lz$Mz$Nz$Jz$Oz$Pz$Qz$Rz$Sz$Tz$Uz$Vz$Wz$Xz$Yz$Zz$az$bz$cz$dz$ez$fz$gz$hz$iz$jz$kz$lz$mz$nz$oz$pz$qz$rz$sz$tz$uz$vz$wz$gz$tz$Rz$xz$yz$ABz$BBz$CBz$DBz$EBz$Uz$FBz$GBz$Xz$HBz$IBz$JBz$Rz$xz$Qz$KBz$LBz$MBz$NBz$OBz$PBz$EBz$Uz$FBz$QBz$Tz$Uz$RBz$Rz$SBz$TBz$UBz$VBz$WBz$XBz$YBz$ZBz$MBz$aBz$bBz$cBz$HBz$IBz$JBz$cBz$dBz$eBz$fBz$gBz$hBz$iBz$jBz$kBz$lBz$mBz$nBz$oBz$pBz$qBz$rBz$sBz$tBz$uBz$vBz$wBz$xBz$yBz$ACz$iBz$BCz$CCz$DCz$ECz$Rz$SBz$TBz$FCz$Rz$xz$Qz$GCz$HCz$ICz$JCz$KCz$LCz$MCz$NCz$OCz$PCz$QCz$RCz$Az$SCz$TCz$UCz$OBz$VCz$WCz$XCz$YCz$ZCz$aCz$bCz$cCz$dCz$eCz$fCz$Lz") && { LC_ALL=en_US.UTF-8; echo_warn $'\n'"Предупреждение: установленная кодировка не поддерживает символы Unicode"; echo_info "Кодировка была изменена на ${c_val}en_US.UTF-8${c_info}"$'\n'; }
        [[ "$( echo -n 'тест' | wc -m )" != 4 || "$( printf '%x' "'й" )" != 439 ]] && {
            echo_warn "Предупреждение: обнаружена проблема с кодировкой. Символы Юникода (в т.ч. кириллические буквы) не будут корректно обрабатываться и строки описаний будут заменены на символы '�'. Попробуйте запустить скрипт другим способом (SSH?)"
            echo_tty
            echo_warn "Warning: An encoding problem has been detected. Unicode characters (including Cyrillic letters) will not be processed correctly and description lines will be replaced with '�' characters. Try running the script in a different way from (SSH?)"
            echo_tty
            opt_rm_tmpfs=false
            ! $silent_mode && { read_question 'Вы хотите продолжить? Do you want to continue?' || exit_clear; }
        }

        check_min_version 7.64 $( curl --version | grep -Po '^curl \K[0-9\.]+' ) || { echo_err "Ошибка: версия утилиты curl меньше требуемой ${c_val}7.6${c_err}. Обновите пакет/систему"; exit 1; }
        configure_api_token init
        check_min_version 7.2 "$data_pve_version" || { echo_err "Ошибка: версия PVE '$data_pve_version' уже устарела и установка стендов данным скриптом не поддерживается."$'\nМиннимально подерживаемая версия: PVE 7.2'; exit_clear; }
        create_access_network=$( check_min_version 8 "$data_pve_version" && echo true || echo false )
        check_min_version 8.3 "$data_pve_version" && var_pve_passwd_min=8 || var_pve_passwd_min=5

        return
    }

    [[ "$1" == 'install' ]] && {
        ! $create_access_network && echo_warn "Предупреждение: версия PVE ${c_val}$data_pve_version${c_warn} имеет меньший функционал, чем последняя версия PVE и некоторые опции установки будут пропущены"
        # [[ "$opt_sel_var" -gt 0 && $(eval "printf '%s\n' \${!config_stand_${opt_sel_var}_var[@]}" | grep -Pv '^stand_config' | wc -l) -gt 0 ]] && { echo_err 'Ошибка: был выбран несуществующий вариант развертки стенда или нечего разворачивать. Выход'; exit_clear; }
        [[ "${#opt_stand_nums[@]}" -gt 10 ]] && echo_warn -e "Предупреждение: конфигурация настроена на развертку ${#opt_stand_nums[@]} стендов!\n Развертка более 10 стендов на одном сервере (в зависимости от мощности \"железа\", может и меньше) может вызвать проблемы с производительностью"
        [[ "${#opt_stand_nums[@]}" -gt 100 ]] && { echo_err "Ошибка: невозможно (бессмысленно) развернуть на одном стенде более 100 стендов. Выход"; exit_clear; }
        for check_func in configure_{poolname,wan_vmbr,imgdir,username,storage,roles}; do
            echo_verbose "Проверка функционала $check_func"
            $check_func $1
        done
        return 0
    }

    local count
    for var in $( compgen -v | grep -P '^config_stand_[1-9][0-9]{0,3}_var$' | awk '{if (NR>1) printf " ";printf $0}' ); do
        count=$( eval "printf '%s\n' \${!$var[@]}" | grep -Fxvc 'stand_config' )
        [[ "$count" != "$( eval "printf '%s\n' \${!$var[@]}" | grep -Pc '^vm_\d{1,2}$' )" ]] \
            && { echo_err "Ошибка: обнаружены некорректные элементы конфигурации ${c_val}$var${c_err}. Выход"; exit_clear; }
    done

    for desc in pool_desc access_user_desc access_auth_pam_desc access_auth_pve_desc; do
        ! descr_string_check "${config_base[$desc]}" && { echo_err "Ошибка: описание '$desc' некорректно. Выход"; exit_clear; }
    done

    [[ "${config_base[access_auth_pam_desc]}" != '' && "${config_base[access_auth_pam_desc]}" == "${config_base[access_auth_pve_desc]}" ]] && { echo_err 'Ошибка: выводимое имя типов аутентификации не должны быть одинаковыми'; exit_clear; }

    for val in take_snapshots access_create access_user_enable run_vm_after_installation create_templates_pool create_linked_clones; do
        ! isbool_check "${config_base[$val]}" && { echo_err "Ошибка: значение переменной конфигурации $val должна быть bool и равляться true или false. Выход"; exit_clear; }
    done
    ! isdigit_check "${config_base[access_pass_length]}" 5 20 && { echo_err "Ошибка: значение переменной конфигурации access_pass_length должнно быть числом от $var_pve_passwd_min до 20. Выход"; exit_clear; }
    [[ "${config_base[access_pass_length]}" -lt $var_pve_passwd_min ]] && { config_base[access_pass_length]=$var_pve_passwd_min; echo_warn "Минимальная длина паролей пользователей установлена на ${c_val}$var_pve_passwd_min${c_warn}. Причина: требование безопасности PVE"; }
    isregex_check "[${config_base[access_pass_chars]}]" && deploy_access_passwd test || { echo_err "Ошибка: паттерн regexp '[${config_base[access_pass_chars]}]' для разрешенных символов в пароле некорректен или не захватывает достаточно символов для составления пароля. Выход"; exit_clear; }
}

function get_dict_config() {
    [[ "$1" == '' || "$2" == '' ]] && exit_clear
    #isdict_var_check "${!2}" || { echo "Ошибка: get_dict_config. Вторая входная переменная не является типом dictionary"; exit_clear; }

    local -n "config_var=$1"
    local -n "dict_var=$2"

    [[ "$config_var" == '' ]] && { [[ "$3" == noexit ]] && return 1; echo_err "Ошибка: конфиг '$1' пуст"; exit_clear; }
    local var value i=0
    while IFS= read -r line || [[ -n $line ]]; do
        var=$( echo $line | grep -Po '^\s*\K[\w]+(?=\ =\ )' )
        value=$( echo $line | grep -Po '^\s*[\w]+\ =\ \s*\K.*?(?=\s*$)' )
        [[ "$var" == '' && "$value" == '' ]] && continue
        ((i++))
        [[ "$var" == '' || "$value" == '' ]] && { echo_err "Ошибка: переменая $1. Не удалось прочитать конфигурацию. Строка $i: '$line'"; exit_clear; }
        dict_var["$var"]="$value" || { echo_err "Ошибка: не удалось записать в словарь"; exit_clear; }
    done < <(printf '%s' "$config_var")
}

function get_dict_values() {
    [[ "$1" == '' || "$2" == '' ]] && { echo_err "Ошибка get_dict_values"; exit_clear; }

    local -n "config_var1=$1"
    local -A dict
    get_dict_config "$1" dict noexit
    shift
    while [[ "$1" != '' ]]; do
        [[ "$1" =~ ^[a-zA-Z\_][0-9a-zA-Z\_]{0,32}(\[[a-zA-Z\_][[0-9a-zA-Z\_]{0,32}\])?\=[a-zA-Z\_]+$ ]] || { echo_err "Ошибка get_dict_values: некорректый аргумент '$1'"; exit_clear; }
        local -n ref_var="${1%=*}"
        local opt_name="${1#*=}"
        for opt in "${!dict[@]}"; do
            [[ "$opt" == "$opt_name" ]] && ref_var=${dict[$opt]} && break
        done
        shift
    done
}

function get_dict_value() {
    [[ "$1" == '' || "$2" == '' ]] && { echo_err "Ошибка get_dict_value"; exit_pid; }
    local -n "ref_config_var=$1"
    echo -n "$ref_config_var" | grep -Po "^$2 = \K.*"
}

function run_cmd() {
    local to_exit=true

    [[ "$1" == '/noexit' ]] && to_exit=false && shift
    [[ "$1" == '/pipefail' ]] && { set -o pipefail; shift; }
    [[ "$1" == '' ]] && { echo_err 'Ошибка run_cmd: нет команды'; exit_clear; }

    if $opt_dry_run; then
        if ! $opt_verbose && [[ "$1" == pve_api_request || "$1" == pve_tapi_request ]]; then echo_tty "[${c_warning}Выполнение запроса API${c_null}] ${@:3}"
        else echo_tty "[${c_warning}Выполнение команды${c_null}] $@"; fi
    else
        local return_cmd='' code
        if [[ "$1" == pve_api_request || "$1" == pve_tapi_request ]]; then
            eval "$@" >&2
            code=$?
        else
            return_cmd=$( eval "$@" 2>&1 )
            code=$?
        fi
        if [[ "$code" == 0 ]]; then
            $opt_verbose && {
                if [[ "$1" == pve_api_request || "$1" == pve_tapi_request ]]; then echo_tty "[${c_ok}Выполнен запрос API${c_null}] ${c_info}${@:3}"
                else echo_tty "[${c_ok}Выполнена команда${c_null}] ${c_info}$@${c_null}"; fi
            }
        else
            ! $to_exit && {
                echo_tty "[${c_warning}Выполнена команда${c_null}] ${c_info}$@${c_null}"
                [[ "$return_cmd" != '' ]] && echo_tty "${c_red}Error output: ${c_warning}$return_cmd${c_null}"
                return $code
            }
            [[ "$1" == pve_api_request || "$1" == pve_tapi_request ]] && echo_tty "[${c_err}Запрос API${c_null}] $3 ${config_base[pve_api_url]}${@:4}"
            echo_err "Ошибка выполнения команды: $@"
            echo_tty "${c_red}Error output: ${c_warning}$return_cmd${c_null}"
            exit_clear
        fi
    fi
    set +o pipefail
    return 0
}

function deploy_stand_config() {

    function set_netif_conf() {
        [[ "$1" == '' || "$2" == '' && "$1" != test ]] && { echo_err 'Ошибка: set_netif_conf нет аргумента'; exit_clear; }
        [[ "$data_aviable_net_models" == '' ]] && { data_aviable_net_models=$( kvm -net nic,model=help | awk 'NR!=1{if($1=="virtio-net-pci")print "virtio";print $1}' ) || { echo_err "Ошибка: не удалось получить список доступных моделей сетевых устройств"; exit_clear; } }
        [[ "$1" == 'test' ]] && { 
            echo -n "$data_aviable_net_models" | grep -Fxq "$netifs_type" && return 0
            echo_err "Ошибка: указаный в конфигурации модель сетевого интерфейса '$netifs_type' не является корректным"
            echo_err "Список доступных моделей можно узнать командой ${c_val}kvm -net nic,model=help"
            exit_clear
        }

        [[ ! "$1" =~ ^network_?([0-9]+)$ ]] && { echo_err "Ошибка: опция конфигурации ВМ network некорректна '$1'"; exit_clear; }
    
        function add_bridge() {
            local iface="$1" if_desc="$2" special
            [[ "$4" == "" ]] && special=false || special=true
            if [[ "$iface" == "" ]]; then
                create_if=true
                for i in "${!vmbr_ids[@]}"; do
                    [[ -v "Networking[vmbr${vmbr_ids[$i]}]" ]] && continue
                    echo "$pve_net_ifs" | grep -Fxq -- "vmbr${vmbr_ids[$i]}" || { iface="vmbr${vmbr_ids[$i]}"; unset 'vmbr_ids[$i]'; break; }
                done
            fi

            Networking[$iface]="$if_desc"
            ! $special && cmd_line+=" --net$if_num '${netifs_type:-virtio},bridge=$iface$net_options'"

            if_desc=${if_desc/\{0\}/$stand_num}
            $create_if && {
                run_cmd /noexit pve_api_request return_cmd POST "/nodes/$(hostname -s)/network" "'iface=$iface' type=bridge autostart=1 'comments=$if_desc'${vlan_aware}${vlan_slave:+" 'bridge_ports=${$vlan_slave}'"}" \
                    || { echo_err "Интерфейс '$iface' ($if_desc) уже существует! Выход"; exit_clear; } 
                echo_ok "Создан bridge интерфейс ${c_value}$iface${c_info} : ${c_value}$if_desc"
            }

            ! $special && $create_access_network && ${config_base[access_create]} && [[ "${vm_config[access_role]}" != NoAccess || "${config_base[access_role]}" == '' && "${config_base[pool_access_role]}" != '' && "${config_base[pool_access_role]}" != NoAccess ]] && [[ "$access_role" != NoAccess ]] && { 
                $create_if && { run_cmd /noexit pve_api_request return_cmd PUT /access/acl "'path=/sdn/zones/localnetwork/$iface' 'users=$username' 'roles=${access_role:-PVEAuditor}'" || { echo_err "Не удалось создать ACL правило для сетевого интерфейса '$iface' и пользователя '$username'"; exit_clear; } } \
                    || run_cmd /noexit pve_api_request return_cmd PUT /access/acl "'path=/sdn/zones/localnetwork/$iface' 'groups=$stands_group' 'roles=${access_role:-PVEAuditor}'" || { echo_err "Не удалось создать ACL правило для сетевого интерфейса '$iface' и пользователя '$username'"; exit_clear; }
            }
            
            $special && eval "$4=$iface"
        }

        function get_host_if() {
            local -n ref_out=$1
            if [[ "$2" == inet ]]; then
                ref_out=${config_base[inet_bridge]}
            elif [[ "$iface" != "" ]]; then
                ref_out=$if_config
                echo "$pve_net_ifs" | grep -Fxq -- "$ref_out" || {
                    echo_err "Ошибка: указанный статически в конфигурации bridge интерфейс '$2' не найден"
                    exit_clear
                }
            else
                ref_out=
            fi
        }

        local if_num=${BASH_REMATCH[1]} if_config="$2" if_desc="$2" create_if=false net_options='' master='' iface='' vlan_aware='' vlan_slave='' access_role=''

        if [[ "$if_config" =~ ^\{\ *bridge\ *=\ *([0-9\.a-z]+|\"\ *((\\\"|[^\"])+)\")\ *(,.*)?\}$ ]]; then
            if_bridge="${BASH_REMATCH[1]/\\\"/\"}"
            if_desc=$( echo "${BASH_REMATCH[2]/\\\"/\"}" | sed 's/[[:space:]]*$//' )
            if_config="${BASH_REMATCH[4]}"
            [[ "$if_config" =~ ,\ *firewall\ *=\ *1\ *($|,.+$) ]] && net_options+=',firewall=1'
            [[ "$if_config" =~ ,\ *state\ *=\ *down\ *($|,.+$) ]] && net_options+=',link_down=1'
            [[ "$if_config" =~ ,\ *access_role\ *=\ *([a-zA-Z0-9_\-]+)\ *($|,.+$) ]] && { access_role=${BASH_REMATCH[1]}; set_role_config $access_role; }
            [[ "$if_config" =~ ,\ *trunks\ *=\ *([0-9\;]*[0-9])\ *($|,.+$) ]] && net_options+=",trunks=${BASH_REMATCH[1]}" && vlan_aware=' bridge_vlan_aware=1'
            [[ "$if_config" =~ ,\ *tag\ *=\ *([1-9][0-9]{0,2}|[1-3][0-9]{3}|40([0-8][0-9]|9[0-4]))\ *($|,.+$) ]] && net_options+=",tag=${BASH_REMATCH[1]}" && vlan_aware=" bridge_vlan_aware=1"
            [[ "$if_config" =~ ,\ *vtag\ *=\ *([1-9][0-9]{0,2}|[1-3][0-9]{3}|40([0-8][0-9]|9[0-4]))\ *($|,.+$) ]] && {
                local tag="${BASH_REMATCH[1]}"
                if [[ "$if_config" =~ ,\ *master\ *=\ *([0-9\.a-z]+|\"\ *((\\\"|[^\"])+)\")\ *($|,.+$) ]]; then
                    local master_desc='' master_if=''
                    master="${BASH_REMATCH[2]/\\\"/\"}"
                    master_desc="$master"
                    [[ "$master" == "" ]] && master_desc="${BASH_REMATCH[1]}" && master="{bridge=$master_desc}" && get_host_if master_if "$master_desc"
                    master_if=$( indexOf Networking "$master" ) || exit_clear;
                    [[ "$master_if" == "" ]] && add_bridge "$master_if" "$master" master_if
                    if [[ -v "Networking[${master_if}.$tag]" && "${Networking[${master_if}.$tag]}" != "{vlan=$if_bridge}" ]]; then
                        echo_err "Ошибка конфигурации: повторная попытка создать VLAN интерфейс для связки с другим Bridge"; exit_clear
                    elif [[ ! -v "Networking[$master_if.$tag]" ]]; then
                        [[ "$if_desc" == "" ]] && if_desc="$if_bridge"
                        run_cmd /noexit pve_api_request return_cmd POST "/nodes/$(hostname -s)/network" "'iface=$master_if.$tag' type=vlan autostart=1 'comments=$master_desc => $if_desc'" \
                            || { echo_err "Интерфейс '$iface' ($if_desc) уже существует! Выход"; exit_clear; }
                        echo_ok "Создан VLAN интерфейс $master_if.$tag : '$master_desc => $if_desc'${c_null}"
                        Networking["${master_if}.$tag"]="{vlan=$if_bridge}"
                    fi
                    vlan_slave="$master_if.$tag"
                else
                    echo_err "Ошибка конфигурации: интерфейс '$2': объявлен master интерфейс, но не объявлен vlan tag"; exit_clear
                fi
            }
            [[ "$if_desc" == "" ]] && if_config="$if_bridge" && if_desc="{bridge=$if_bridge}" || if_config=""
        elif [[ "$if_desc" =~ ^\{.*\}$ ]]; then 
            echo_err "Ошибка: некорректное значение подстановки настройки '$1 = $2' для ВМ '$elem'"
            exit_clear
        else
            if_config=""
        fi

        for net in "${!Networking[@]}"; do
            [[ "${Networking["$net"]}" != "$if_desc" ]] && continue
            cmd_line+=" --net$if_num '${netifs_type:-virtio},bridge=$net$net_options'"
            ! $opt_dry_run && [[ "$vlan_slave" != '' || "$vlan_aware" != '' ]] && ! [[ "$vlan_slave" != '' && "$vlan_aware" != '' ]] && {
                local port_info if_update=false
                pve_api_request port_info GET "/nodes/$(hostname -s)/network/$net" || { echo_err "Ошибка: не удалось получить параметры сетевого интерфейса ${c_val}$net"; exit_clear; }

                [[ "$port_info" =~ (,|\{)\"bridge_vlan_aware\":1(,|\}) ]] && vlan_aware=' bridge_vlan_aware=1' || { [[ "$vlan_aware" != '' ]] && if_update=true; }
                [[ "$port_info" =~ (,|\{)\"bridge_ports\":\"([^\"]+)\" ]] && {
                    { [[ "$vlan_slave" == '' ]] || printf '%s\n' ${BASH_REMATCH[2]} | grep -Fxq -- "$vlan_slave"; } && vlan_slave="${BASH_REMATCH[2]}" || {
                        vlan_slave="$vlan_slave ${BASH_REMATCH[2]}"
                        if_update=true
                    }
                } || [[ "$vlan_slave" != '' ]] && if_update=true
                
                $if_update && run_cmd pve_api_request return_cmd PUT "/nodes/$(hostname -s)/network/$net" "type=bridge${vlan_aware}${vlan_slave:+" 'bridge_ports=${$vlan_slave}'"}"
            }
            return 0
        done

        get_host_if iface "$if_config"
        
        add_bridge "$iface" "$if_desc"
        return 0

    }

    function set_disk_conf() {
        [[ "$1" == '' || "$2" == '' && "$1" != test ]] && { echo_err 'Ошибка: set_disk_conf нет аргумента'; exit_clear; }
        [[ "$1" == 'test' ]] && { [[ "$disk_type" =~ ^(ide|sata|scsi|virtio)$ ]] && return 0; echo_err "Ошибка: указаный в конфигурации тип диска '$disk_type' не является корректным [ide|sata|scsi|virtio]"; exit_clear; }
        [[ ! "$1" =~ ^(boot_|)disk_?[0-9]+ ]] && { echo_err "Ошибка: неизвестный параметр ВМ '$1'" && exit_clear; }
        local _exit=false
        case "$disk_type" in
            ide)    [[ "$disk_num" -le 4  ]] || _exit=true;;
            sata)   [[ "$disk_num" -le 6  ]] || _exit=true;;
            scsi)   [[ "$disk_num" -le 31 ]] || _exit=true;;
            virtio) [[ "$disk_num" -le 16 ]] || _exit=true;;
        esac
        $_exit && { echo_err "Ошибка: невозможно присоедиить больше $((disk_num-1)) дисков типа '$disk_type' к ВМ '$elem'. Выход"; exit_clear;}

        if [[ "${BASH_REMATCH[1]}" != boot_ ]] && [[ "$2" =~ ^([0-9]+(|\.[0-9]+))\ *([gGГг][bBБб]?)?$ ]]; then
            cmd_line+=" --${disk_type}${disk_num} '${config_base[storage]}:${BASH_REMATCH[1]},format=$config_disk_format'";
        else
            local file="$2"
            get_file file || exit_clear
            cmd_line+=" --${disk_type}${disk_num} '${config_base[storage]}:0,format=$config_disk_format,import-from=$file'"
            [[ "$boot_order" != '' ]] && boot_order+=';'
            boot_order+="${disk_type}${disk_num}"
        fi

        ((disk_num++))
    }

    function set_role_config() {
        [[ "$1" == '' ]] && { echo_err 'Ошибка: set_role_config нет аргумента'; exit_clear; }
        [[ "$1" =~ ^[a-zA-Z0-9\.\-_]+$ ]] || { echo_err "Ошибка: имя роли '$1' некорректное"; exit_clear; }
        local i role role_exists
        role_exists=false
        for ((i=1; i<=$(echo -n "${roles_list[roleid]}" | grep -c '^'); i++)); do
            role=$( echo "${roles_list[roleid]}" | sed -n "${i}p" )
            [[ "$1" != "$role" ]] && continue
            [[ -v "config_access_roles[$1]" && "$( echo "${roles_list[privs]}" | sed -n "${i}p" )" != "${config_access_roles[$1]}" ]] && {
                    run_cmd pve_api_request return_cmd PUT "/access/roles/$1" "'privs=${config_access_roles[$1]}'"
                    echo_ok "Обновлены права access роли ${c_val}$1"
                    roles_list[roleid]=$( echo "$1"; echo -n "${roles_list[roleid]}" )
                    roles_list[privs]=$( echo "${config_access_roles[$1]}"; echo -n "${roles_list[privs]}" )
            }
            role_exists=true
            break
        done
        ! $role_exists && {
            [[ ! -v "config_access_roles[$1]" ]] && { echo_err "Ошибка: в конфигурации для установки ВМ '$elem' установлена несуществующая access роль '$1'. Выход"; exit_clear; }
            run_cmd pve_api_request return_cmd POST /access/roles "'roleid=$1' 'privs=${config_access_roles[$1]}'"
            echo_ok "Создана access роль ${c_val}$1"
            roles_list[roleid]=$( echo "$1"; echo -n "${roles_list[roleid]}" )
            roles_list[privs]=$( echo "${config_access_roles[$1]}"; echo -n "${roles_list[privs]}" )
        }
    }

    function set_machine_type() {
        [[ "$1" == '' ]] && { echo_err 'Ошибка: set_machine_type нет аргумента'; exit_clear; }
        local machine_list=$( kvm -machine help | awk 'NR>1{print $1}' )
        local type=$1
        if ! echo "$machine_list" | grep -Fxq "$type"; then
            if [[ "$type" =~ ^((pc)-i440fx|pc-(q35))-[0-9]+.[0-9]+$ ]]; then
                type=${BASH_REMATCH[2]:-${BASH_REMATCH[3]}}
                echo_warn "[Предупреждение]: в конфигурации ВМ '$elem' указанный тип машины '$1' не существует в этой версии PVE/QEMU. Заменен на последнюю доступную версию pc-${type/pc/i440fx}"
            else
                echo_err "Ошибка: в конфигурации ВМ '$elem' указан неизвестный тип машины '$1'. Ошибка или старая версия PVE?. Выход"
                exit_clear
            fi
        fi
        cmd_line+=" --machine '$type'"
    }

    function set_firewall_opt() {
        [[ "$1" == '' ]] && return 1
        local opt=''
        echo -n "$1" | grep -Pq '^{[^{}]*}$' || { echo_err "Ошибка set_firewall_opt: ВМ '$elem' некорректный синтаксис"; exit_clear; }
        echo -n "$1" | grep -Pq '(^{|,) ?enable ?= ?1 ?(,? ?}$|,)' && opt+=" enable=1"
        echo -n "$1" | grep -Pq '(^{|,) ?dhcp ?= ?1 ?(,? ?}$|,)' && opt+=" dhcp=1"
        [[ "$opt" != '' ]] && run_cmd pve_api_request return_cmd PUT "/nodes/$( hostname -s )/qemu/$vmid/firewall/options" "${opt}"
    }

    [[ "$1" == '' ]] && { echo_err "Внутренняя ошибка скрипта установки стенда"; exit_clear; }

    local -n "config_var=config_stand_${opt_sel_var}_var"
    local -A Networking=()

    local stand_num=$1
    local vmid=$((${config_base[start_vmid]} + $2 * 100 + 1))
    [[ "$stands_group" == '' ]] && { echo_err "Ошибка: не указана группа стендов"; exit_clear; }
    local pool_name="${config_base[pool_name]/\{0\}/$stand_num}"

    local pve_net_ifs=''
    pve_api_request pve_net_ifs GET /nodes/$(hostname -s)/network || { echo_err "Ошибка: не удалось загрузить список сетевых интерфейсов"; exit_clear; }
    pve_net_ifs=$( echo -n "$pve_net_ifs" | grep -Po '({|,)"iface":"\K[^"]+' )

    run_cmd /noexit pve_api_request return_cmd POST /pools "'poolid=$pool_name' 'comment=${config_base[pool_desc]/\{0\}/$stand_num}'" || { echo_err "Ошибка: не удалось создать пул '$pool_name'"; exit_clear; }
    run_cmd pve_api_request return_cmd PUT /access/acl "'path=/pool/$pool_name' 'groups=$stands_group' roles=NoAccess  propagate=0"
    echo_ok "Создан пул стенда ${c_val}$pool_name"

    ${config_base[access_create]} && {
        local username="${config_base[access_user_name]/\{0\}/$stand_num}@pve"
        
        run_cmd /noexit pve_api_request return_cmd POST /access/users "'userid=$username' 'groups=$stands_group' 'enable=$( get_int_bool "${config_base[access_user_enable]}" )' 'comment=${config_base[access_user_desc]/\{0\}/$stand_num}'" \
            || { echo_err "Ошибка: не удалось создать пользователя '$username'"; exit_clear; }
        
        if [[ "${config_base[pool_access_role]}" != '' && "${config_base[pool_access_role]}" != NoAccess ]]; then
            set_role_config "${config_base[pool_access_role]}"
            run_cmd pve_api_request return_cmd PUT /access/acl "'path=/pool/$pool_name' 'users=$username' 'roles=${config_base[pool_access_role]}'"
        else run_cmd pve_api_request return_cmd PUT /access/acl "'path=/pool/$pool_name' 'users=$username' roles=PVEAuditor propagate=0"; fi
        echo_ok "Создан пользователь стенда ${c_val}$username"
    }

    local cmd_line='' netifs_type='virtio' disk_type='scsi' disk_num=0 boot_order='' vm_template='' vm_name=''
    local -A vm_config=()

    for elem in $(printf '%s\n' "${!config_var[@]}" | grep -P 'vm_\d+' | sort -V ); do

        netifs_type='virtio'
        disk_type='scsi'
        disk_num=0
        boot_order=''
        vm_config=()
        vm_template="$( get_dict_value config_stand_${opt_sel_var}_var[$elem] config_template; exit 1 )"

        [[ "$vm_template" != '' ]] && {
            [[ -v "config_templates[$vm_template]" ]] || { echo_err "Ошибка: шаблон конфигурации '$vm_template' для ВМ '$elem' не найден. Выход"; exit_clear; }
            get_dict_config "config_templates[$vm_template]" vm_config
        }
        get_dict_config "config_stand_${opt_sel_var}_var[$elem]" vm_config
        vm_name="${vm_config[name]}"
        unset 'vm_config[name]' 'vm_config[os_descr]' 'vm_config[templ_descr]' 'vm_config[config_template]'

        [[ "$vm_name" == '' ]] && vm_name="$elem"

        cmd_line="qm create '$vmid' --name '$vm_name' --pool '$pool_name'"

        [[ "${vm_config[netifs_type]}" != '' ]] && netifs_type="${vm_config[netifs_type]}" && unset -v 'vm_config[netifs_type]'
        [[ "${vm_config[disk_type]}" != '' ]] && disk_type="${vm_config[disk_type]}" && unset -v 'vm_config[disk_type]'

        set_netif_conf test && set_disk_conf test || exit_clear

        for opt in $( printf '%s\n' "${!vm_config[@]}" | sort -V ); do
            case "$opt" in
                startup|tags|ostype|serial0|serial1|serial2|serial3|agent|scsihw|cpu|cores|memory|bwlimit|description|args|arch|vga|kvm|rng0|acpi|tablet|reboot|startdate|tdf|cpulimit|balloon|hotplug)
                    cmd_line+=" --$opt '${vm_config[$opt]}'";;
                network*) set_netif_conf "$opt" "${vm_config[$opt]}";;
                bios) [[ "${vm_config[$opt]}" == ovmf ]] && cmd_line+=" --bios 'ovmf' --efidisk0 '${config_base[storage]}:0,format=$config_disk_format'" || cmd_line+=" --$opt '${vm_config[$opt]}'";;
                boot_disk*|disk*) set_disk_conf "$opt" "${vm_config[$opt]}";;
                access_role) ${config_base[access_create]} && set_role_config "${vm_config[$opt]}";;
                machine) set_machine_type "${vm_config[$opt]}";;
                firewall_opt) continue;;
                *) echo_warn "[Предупреждение]: обнаружен неизвестный параметр конфигурации '$opt = ${vm_config[$opt]}' ВМ '$vm_name'. Пропущен"
            esac
        done
        [[ "$boot_order" != '' ]] && cmd_line+=" --boot 'order=$boot_order'"

        run_cmd /noexit "$cmd_line" || { echo_err "Ошибка: не удалось создать ВМ '$vm_name' стенда '$pool_name'. Выход"; exit_clear; }

        set_firewall_opt "$( get_dict_value config_stand_${opt_sel_var}_var[$elem] firewall_opt )"

        ${config_base[access_create]} && [[ "${vm_config[access_role]}" != '' ]] && run_cmd pve_api_request return_cmd PUT /access/acl "'path=/vms/$vmid' 'roles=${vm_config[access_role]}' 'users=$username'"

        ${config_base[take_snapshots]} && run_cmd "pvesh create '/nodes/$( hostname -s )/qemu/$vmid/snapshot' --snapname 'Start' --description 'Исходное состояние ВМ'"

        ${config_base[run_vm_after_installation]} && manage_bulk_vm_power --add "$(hostname -s)" "$vmid"

        echo_ok "Конфигурирование ВМ ${c_ok}$vm_name${c_null} (${c_info}$vmid${c_null}) завершено"
        ((vmid++))
    done

    echo_ok "${c_info}Конфигурирование стенда ${c_value}$pool_name${c_info} завершено${c_null}"
}

var_passwd_chars=$(GB_='T';QC_='ц';a_='n';C_='h';CC_='и';A_='e';ED_='Э';RB_=',';tC_='Т';FC_='л';w_='K';OB_=':';t_='H';UB_='№';D_='o';vC_='Ф';xB_='е';XB_='#';uC_='У';aC_='А';XC_='э';WB_='@';f_='t';VB_='!';vB_='г';d_='r';jB_='-';jC_='И';kB_='_';FB_='S';uB_='в';p_='D';g_='u';dC_='Г';sB_='а';SC_='ш';bB_='&';hC_='Ж';E_=' ';DD_='Ь';R_='b';k_='y';N_='7';v_='J';eB_=')';B_='c';pC_='О';BC_='з';NB_='"';DC_='й';eC_='Д';y_='M';U_='g';EB_='R';oC_='Н';CB_='P';wB_='д';AC_='ж';GC_='м';bC_='Б';n_='B';mB_='=';ZB_='%';KC_='р';s_='G';M_='6';X_='k';m_='A';O_='8';q_='E';NC_='у';RC_='ч';FD_='Ю';F_=''\''';UC_='ъ';sC_='С';IB_='V';aB_='^';j_='x';OC_='ф';MC_='т';u_='I';SB_='.';r_='F';I_='2';WC_='ь';gC_='Ё';lB_='+';o_='C';K_='4';J_='3';rB_='`';G_='0';tB_='б';h_='v';BB_='O';e_='s';qB_='~';mC_='Л';cB_='*';EC_='к';L_='5';c_='q';YC_='ю';HC_='н';iB_='}';kC_='Й';JB_='W';VC_='ы';fB_='[';_=$'\n';PC_='х';Z_='m';DB_='Q';Q_='a';H_='1';cC_='В';ZC_='я';T_='f';lC_='К';P_='9';x_='L';LC_='с';MB_='Z';GD_='Я';S_='d';CD_='Ы';dB_='(';KB_='X';TC_='щ';pB_='/';V_='i';b_='p';YB_='$';yC_='Ш';AB_='N';oB_='|';LB_='Y';JC_='п';Y_='l';iC_='З';nC_='М';W_='j';i_='w';xC_='Ц';qC_='П';QB_='<';fC_='Е';TB_='?';PB_=';';nB_='\';rC_='Р';wC_='Х';HD_='>';IC_='о';HB_='U';hB_='{';l_='_';BD_='Ъ';gB_=']';AD_='Щ';yB_='ё';eval "$A_$B_$C_$D_$E_$F_$G_$H_$I_$J_$K_$L_$M_$N_$O_$P_$Q_$R_$B_$S_$A_$T_$U_$C_$V_$W_$X_$Y_$Z_$a_$D_$b_$c_$d_$e_$f_$g_$h_$i_$j_$k_$l_$m_$n_$o_$p_$q_$r_$s_$t_$u_$v_$w_$x_$y_$AB_$BB_$CB_$DB_$EB_$FB_$GB_$HB_$IB_$JB_$KB_$LB_$MB_$NB_$OB_$PB_$QB_$E_$RB_$SB_$TB_$UB_$VB_$WB_$XB_$YB_$ZB_$aB_$bB_$cB_$dB_$eB_$fB_$gB_$hB_$iB_$jB_$kB_$lB_$mB_$nB_$oB_$pB_$qB_$rB_$sB_$tB_$uB_$vB_$wB_$xB_$yB_$AC_$BC_$CC_$DC_$EC_$FC_$GC_$HC_$IC_$JC_$KC_$LC_$MC_$NC_$OC_$PC_$QC_$RC_$SC_$TC_$UC_$VC_$WC_$XC_$YC_$ZC_$aC_$bC_$cC_$dC_$eC_$fC_$gC_$hC_$iC_$jC_$kC_$lC_$mC_$nC_$oC_$pC_$qC_$rC_$sC_$tC_$uC_$vC_$wC_$xC_$yC_$AD_$BD_$CD_$DD_$ED_$FD_$GD_$F_$nB_$F_$PB_$A_$B_$C_$D_$E_$YB_$F_$nB_$a_$nB_$A_$fB_$H_$Z_$nB_$A_$fB_$G_$PB_$P_$M_$Z_$CB_$d_$D_$j_$Z_$D_$j_$E_$IB_$q_$E_$m_$g_$f_$D_$Z_$Q_$f_$V_$B_$E_$e_$f_$Q_$a_$S_$E_$S_$A_$b_$Y_$D_$k_$Z_$A_$a_$f_$E_$Q_$a_$S_$E_$B_$D_$a_$T_$V_$U_$g_$d_$Q_$f_$V_$D_$a_$nB_$A_$fB_$Z_$E_$e_$B_$d_$V_$b_$f_$E_$R_$k_$E_$nB_$A_$fB_$H_$PB_$J_$I_$Z_$CB_$Q_$h_$A_$Y_$m_$r_$nB_$A_$fB_$Z_$nB_$a_$s_$V_$f_$t_$g_$R_$E_$Y_$V_$a_$X_$OB_$E_$nB_$A_$fB_$H_$PB_$J_$K_$Z_$nB_$A_$fB_$K_$Z_$nB_$A_$gB_$O_$PB_$PB_$C_$f_$f_$b_$e_$OB_$pB_$pB_$U_$V_$f_$C_$g_$R_$SB_$B_$D_$Z_$pB_$CB_$Q_$h_$A_$Y_$m_$r_$pB_$CB_$IB_$q_$jB_$m_$FB_$p_$Q_$o_$jB_$n_$m_$FB_$t_$nB_$Q_$C_$f_$f_$b_$e_$OB_$pB_$pB_$U_$V_$f_$C_$g_$R_$SB_$B_$D_$Z_$pB_$CB_$Q_$h_$A_$Y_$m_$r_$pB_$CB_$IB_$q_$jB_$m_$FB_$p_$Q_$o_$jB_$n_$m_$FB_$t_$nB_$A_$gB_$O_$PB_$PB_$nB_$Q_$nB_$A_$fB_$Z_$nB_$a_$F_$HD_$pB_$S_$A_$h_$pB_$f_$f_$k_")
function deploy_access_passwd() {
    var_passwd_chars=$( echo -n $var_passwd_chars | grep -Po -- "[${config_base[access_pass_chars]}]" | tr -d '\n' )

    [[ "$1" == test ]] && { [[ $( echo -n "$var_passwd_chars" | wc -m ) -ge 1 ]] && return 0 || return 1; }
    [[ "${#opt_stand_nums[@]}" == 0 ]] && return 0

    local format_opt=1
    ! $silent_mode && {
        echo_tty $'\n\n\n'"Выберите вид отображения учетных данных (логин/паролей) для доступа к стендам:"
        echo_tty "  1. Обычный   ${c_value}{username} | {passwd}${c_null}"
        echo_tty "  2. HTML-вариант для вставки в Excel"
        echo_tty "  3. HTML-вариант для вставки в Excel (с заголовками к каждой записи)"
        echo_tty '  4. CSV: универсальный табличный вариант'
        echo_tty '  5. CSV: универсальный табличный вариант (с заголовками к каждой записи)'
        echo_tty
        format_opt=$(read_question_select 'Вариант отображения' '^([1-5]|)$' )
    }

    [[ $format_opt == '' ]] && format_opt=1

    [[ $format_opt != 1 ]] && {
        local -A pve_nodes; local i pve_url max_index
        jq_data_to_array /cluster/status pve_nodes
        max_index=$( printf '%s\n' "${!pve_nodes[@]}" | sort -Vr | head -n 1 | grep -Po '^\d+' )
        for ((i=0; i<=$max_index; i++)); do
            [[ "${pve_nodes[$i,local]}" == '1' ]] && pve_url="https://${pve_nodes[$i,ip]}:8006" && break
        done
        unset pve_nodes
        local val=$(read_question_select "Введите отображаемый адрес (URL) сервера Proxmox VE" '' '' '' "$pve_url" )
        [[ "$val" != '' ]] && pve_url=$val
    }

    local nl=$'\n' tab=$'\t' table username passwd \
            header_html="<tr><th>Точка подключения к гипервизору <br>(IP или доменное имя:порт)</th><th>Учётная запись для входа в гипервизор <br>(логин | пароль)</th></tr>" \
            service_user_password=''
    case $format_opt in
        2) table+=$header_html;;
        4) table+="\"Точка подключения к гипервизору$nl(IP или доменное имя:порт)\";\"Учётная запись для входа в гипервизор$nl(логин | пароль)\"$nl";;
    esac

    check_min_version 8.2 "$data_pve_version"  && service_user_password="'confirmation-password={ticket_user_pwd}'"
    for username in "${opt_stand_nums[@]}"; do
        [[ "$1" != set ]] && username="${config_base[access_user_name]/\{0\}/$username}@pve"
        [[ $format_opt == 3 ]] && table+="$header_html"
        [[ $format_opt == 5 ]] && table+="\"Точка подключения к гипервизору$nl(IP или доменное имя:порт)\";\"Учётная запись для входа в гипервизор$nl(логин | пароль)\"$nl"

        passwd=
        for ((i=0;i<${config_base[access_pass_length]};i++)); do
            passwd+=${var_passwd_chars:RANDOM%${#var_passwd_chars}:1}
        done

        run_cmd /noexit pve_tapi_request return_cmd PUT /access/password "'userid=$username' 'password=$passwd' $service_user_password" || { echo_err "Ошибка: не удалось установить пароль пользователю $username"; exit_clear; }
        username=${username::-4}
        case $format_opt in
            1) table+="$username | $passwd$nl";;
            2|3) table+="<tr class=\"data\"><td>$pve_url</td><td>$username | $passwd</td></tr>";;
            4|5) table+="\"$pve_url\";\"$username | $passwd\"$nl";;
        esac
    done
    [[ "$format_opt" == 2 || "$format_opt" == 3 ]] && table="<style>.data{font-family:Consolas;text-align:center}br{mso-data-placement:same-cell}</style><table border="1" style=\"white-space:nowrap\">$table</table>"
    [[ "$format_opt" == 1 || "$format_opt" == 4 || "$format_opt" == 5 ]] && table=${table::-1}
    echo_info $'\n\n#>=========== Учетные данные пользователей ==========<#\n'
    [[ ! -t 1 ]] && echo "${c_error}$table${c_null}" | sed -r 's/\x1B\[([0-9]{1,3}(;[0-9]{1,2};?)?)?[mGK]//g;s/\r//g'
    echo_tty "${c_error}$table${c_null}"
    echo_info $'\n#>====================== Конец ======================<#\n'
}


function install_stands() {

    is_show_config=false

    configure_varnum || return 0
    configure_standnum
    check_config install

    local val=''
    for opt in pool_desc access_user_desc pool_access_role; do
        val="$( get_dict_value "config_stand_${opt_sel_var}_var[stand_config]" "$opt" )"
        descr_string_check "$val" && [[ "$val" != '' ]] && config_base["$opt"]=$val
    done
    echo_tty "$( show_config )"

    _exit=false
    ! $silent_mode && read_question 'Хотите изменить параметры?' && {
        local opt_names=( inet_bridge storage pool_name pool_desc take_snapshots run_vm_after_installation access_{create,user_{name,desc,enable},pass_{length,chars},auth_{pve,pam}_desc} dry-run verbose)
        while true; do
            echo_tty "$( show_config install-change )"
            echo_tty
            local switch=$( read_question_select 'Выберите номер настройки для изменения' '^[0-9]*$' 0 $( ${config_base[access_create]} && echo 16 || echo 9 ) )
            echo_tty
            [[ "$switch" == 0 ]] && break
            [[ "$switch" == '' ]] && { $_exit && break; _exit=true; continue; }
            [[ "$switch" -ge 8 && "${config_base[access_create]}" == false ]] && (( switch+=7 ))
            local opt=$( printf '%s\n' "${opt_names[@]}" | sed "$switch!D" )
            val=''
            case $opt in
                pool_name) configure_poolname set install exit false; continue;;
                access_user_name) configure_username set install exit false; continue;;
                storage) config_base[storage]='{manual}'; configure_storage install; continue;;
                inet_bridge) configure_wan_vmbr manual; continue;;
                take_snapshots|access_create|access_user_enable|run_vm_after_installation) config_base[$opt]=$( invert_bool ${config_base[$opt]} ); continue;;
                dry-run) opt_dry_run=$( invert_bool $opt_dry_run ); continue;;
                verbose) opt_verbose=$( invert_bool $opt_verbose ); continue;;
            esac
            val=$( read_question_select "${config_base[_$opt]:-$opt}" '' '' '' "${config_base[$opt]}" )
            [[ "${config_base[$opt]}" == "$val" ]] && continue

            case $opt in
                pool_desc|access_user_desc|access_auth_pve_desc|access_auth_pam_desc)
                    (config_base[$opt]="$val"; [[ "${config_base[access_auth_pam_desc]}" != '' && "${config_base[access_auth_pam_desc]}" == "${config_base[access_auth_pve_desc]}" ]] && echo_err 'Ошибка: видимые имена типов аутентификации не должны быть одинаковыми' ) && continue

                    descr_string_check "$val" || { echo_err 'Ошибка: введенное значение является некорректным'; continue; };;
                access_pass_length) isdigit_check "$val" $var_pve_passwd_min 20 || { echo_err "Ошибка: допустимая длина паролей от $var_pve_passwd_min до 20"; continue; } ;;
                access_pass_chars) isregex_check "[$val]" && ( config_base[access_pass_chars]="$val"; deploy_access_passwd test ) || { echo_err 'Ошибка: введенное значение не является регулярным выражением или не захватывает достаточно символов для составления пароля'; continue; } ;;
                *) echo_err 'Внутреняя ошибка скрипта. Выход'; exit_clear;;
            esac
            [[ $opt == access_create ]] && ! ${config_base[access_create]} && $val && \
                { configure_username set-install exit false || configure_username set set-install exit false || continue; }

            config_base[$opt]="$val"
        done
        echo_tty "$( show_config )"
    }
    local stand_num stands_group=${config_base[pool_name]/\{0\}/"X"} vmbr_ids=( {{1001..9999},{0000..0999},{00..09},{010..099},{0..1000}} )

    val="$( get_dict_value "config_stand_${opt_sel_var}_var[stand_config]" group_display_desc )"
    [[ "$val" == '' ]] && { val="$( get_dict_value "config_stand_${opt_sel_var}_var[stand_config]" description )" || exit_clear; }
    [[ "$val" == '' ]] && val="${config_base[pool_desc]}"
    [[ "$val" == '' ]] && val=${config_base[pool_name]}

    $opt_dry_run && echo_warn '[Предупреждение]: включен режим dry-run. Никакие изменения в конфигурацию/ВМ внесены не будут'
    echo_info "Для выхода из программы нажмите Ctrl-C"
    ! $silent_mode && { read_question 'Начать установку?' || return 0; }
    $silent_mode && { echo_info $'\n'"10 секунд для проверки правильности конфигурации"; sleep 10; }


    # Начало установки
    opt_not_tmpfs=false

    configure_vmid install
    run_cmd pve_api_request return_cmd PUT /cluster/options "'next-id=lower=$(( ${config_base[start_vmid]} + ${#opt_stand_nums[@]} * 100 ))'"

    run_cmd /noexit pve_api_request "''" POST /access/groups "'groupid=$stands_group' 'comment=$val'"
    [[ $? =~ ^0$|^244$ ]] || { echo_err "Ошибка: не удалось создать access группу для стендов '$stands_group'. Выход"; exit_clear; }

    run_cmd pve_api_request return_cmd PUT /access/acl path=/sdn/zones/localnetwork "roles=PVEAuditor 'groups=$stands_group' propagate=0"
    
    local -A roles_list roles_data 
    local max_index i
    jq_data_to_array /access/roles roles_data || exit_clear
    max_index=$( printf '%s\n' "${!roles_data[@]}" | sort -Vr | head -n 1 | grep -Po '^\d+' )
    for ((i=0;i<="$max_index";i++)); do
        roles_list[roleid]+=${roles_data[$i,roleid]}$'\n'
        roles_list[privs]+=${roles_data[$i,privs]//,/ }$'\n'
    done

    ${config_base[run_vm_after_installation]} && manage_bulk_vm_power --init

    for stand_num in "${!opt_stand_nums[@]}"; do
        deploy_stand_config ${opt_stand_nums[stand_num]} $stand_num
    done

    run_cmd "pvesh set '/nodes/$(hostname -s)/network'"

    ${config_base[access_create]} && {
        [[ "${config_base[access_auth_pam_desc]}" != '' ]] && run_cmd pve_api_request return_cmd PUT /access/domains/pam "'comment=${config_base[access_auth_pam_desc]}'"
        [[ "${config_base[access_auth_pve_desc]}" != '' ]] && run_cmd pve_api_request return_cmd PUT /access/domains/pve "default=1 'comment=${config_base[access_auth_pve_desc]}'"
    }

    ${config_base[run_vm_after_installation]} && manage_bulk_vm_power --start-vms

    ${config_base[access_create]} && deploy_access_passwd

    echo_tty $'\n'"${c_ok}Установка завершена.${c_null} Выход"
    exit_clear
}

#       pvesh set /cluster/options --tag-style 'color-map=alt_server:ffcc14;alt_workstation:ac58e4,ordering=config,shape=none'


function check_arg() {
    [[ "$1" == '' || "${1:0:1}" == '-' ]] && { echo_err "Ошибка обработки аргуметов: ожидалось значение. Выход"; exit 1; }
}

function manage_bulk_vm_power() {
    [[ "$1" == '' ]] && exit_clear
    [[ -v bulk_vms_power_list ]] || declare -Ag bulk_vms_power_list

    local action=''
    [[ "$1" == '--add' && "$2" != '' && "$3" != ''  ]] && action='add' && shift
    [[ "$1" == '--start-vms' ]] && action='startall'
    [[ "$1" == '--stop-vms' ]] && action='stopall'
    [[ "$1" == '--init' ]] && { bulk_vms_power_list=(); return; }
    [[ "$action" == '' ]] && exit_clear

    [[ "$action" == add ]] && {
        local node="$1"; shift
        bulk_vms_power_list[$node]+=" $@"
        return 0
    }
    
    local pve_node args act_desc=''
    [[ "$action" == 'startall' ]] && args=" --force '1'" && act_desc="${c_ok}включение${c_null}" || { act_desc="${c_err}выключение${c_null}"; isdigit_check "$2" && args=" --timeout '$2'"; }
    for pve_node in "${!bulk_vms_power_list[@]}"; do
        bulk_vms_power_list[$pve_node]=${bulk_vms_power_list[$pve_node]/# /}
        echo_tty "[${c_ok}Задание${c_null}] Запущено массовое $act_desc машин на узле ${c_val}$pve_node${c_null}. Список ВМ: ${c_val}${bulk_vms_power_list[$pve_node]// /"${c_null}, ${c_val}"}${c_null}"
        run_cmd "pvesh create /nodes/$pve_node/$action --vms '${bulk_vms_power_list[$pve_node]}'$args"
        echo_ok "${act_desc} машин на узле ${c_val}$pve_node${c_null}"
    done
}



function manage_stands() {

    local -A acl_list group_list print_list user_list pool_list

    jq_data_to_array /access/acl acl_list
    jq_data_to_array /access/groups group_list

    local group_name pool_name comment users users_count=0 stands_count=0 max_count

    max_count=$( printf '%s\n' "${!acl_list[@]}" | sort -Vr | head -n 1 | grep -Po '^\d+' ) || max_count=0
    for ((i=0; i<=$max_count; i++)); do
        [[ "${acl_list[$i,type]}" != group ]] && continue
        group_name=${acl_list[$i,ugid]}
        pool_name=${acl_list[$i,path]}
        if [[ "$pool_name" =~ ^\/pool\/(.+) ]] && [[ "${acl_list[$i,roleid]}" == NoAccess && "${acl_list[$i,propagate]}" == 0 ]]; then
            print_list[$group_name]=''
            pool_list[$group_name]+=" ${BASH_REMATCH[1]} "
            pool_list[$group_name]=$( echo "${pool_list[$group_name]}" | tr ' ' '\n' | sed '/^$/d' | sort -uV )
        fi
    done
    max_count=$( printf '%s\n' "${!group_list[@]}" | sort -Vr | head -n 1 | grep -Po '^\d+' ) || max_count=0
    for ((i=0; i<=$max_count; i++)); do
        group_name="${group_list[$i,groupid]}"
        [[ -v "print_list[$group_name]" ]] && {
            comment="${group_list[$i,comment]}"
            users="${group_list[$i,users]}"
            print_list[$group_name]="${c_ok}$group_name${c_null} : $comment"
            user_list[$group_name]=$( echo "$users" | tr -s ',' '\n' | sort -uV )
        }
    done

    [[ ${#print_list[@]} != 0 ]] && echo_tty $'\n\nСписок развернутых конфигураций:' || { echo_info $'\nНе найденно ни одной развернутой конфигурации'; return 0; }
    local i=0
    for item in "${!print_list[@]}"; do
        echo_tty "  $((++i)). ${print_list[$item]//\\\"/\"}"
    done
    [[ $i -gt 1 ]] && i=$( read_question_select 'Выберите номер конфигурации' '^[0-9]+$' 1 $i '' 2 )
    [[ "$i" == '' ]] && return 0
    local j=0
    group_name=''
    for item in "${!print_list[@]}"; do
        ((j++))
        [[ $i != $j ]] && continue
        group_name=$item
        break
    done

    echo_tty $'\nУправление конфигурацией:'
    echo_tty "   1. Включение учетных записей"
    echo_tty "   2. Отключение учетных записей"
    echo_tty "   3. Установка паролей для учетных записей"
    echo_tty "   4. Включить или ${c_warning}перезагрузить${c_null} виртуальные машины"
    echo_tty "   5. Выключить виртуальные машины"
    echo_tty "   6. Откатить виртуальные машины до начального снапшота ${c_value}Start${c_null}"
    echo_tty "   7. Создать снапшоты виртуальных машин"
    echo_tty "   8. Откатить снапшоты виртуальных машин"
    echo_tty "   9. Удалить снапшоты виртуальных машин"
    echo_tty "  10. Удаление стендов"
    local switch=$( read_question_select $'\nВыберите действие' '^([0-9]{1,2}|)$' 1 10 )

    [[ "$switch" == '' ]] && switch=$( read_question_select $'\nВыберите действие' '^([0-9]{1,2}|)$' 1 12 ) && [[ "$switch" == '' ]] && return 0
    if [[ $switch =~ ^[1-3]$ ]]; then
        local user_name enable state usr_range='' usr_count=$(echo -n "${user_list[$group_name]}" | grep -c '^') usr_list=''

        [[ "$usr_count" == 0 ]] && { echo_err "Ошибка: пользователи стендов '$group_name' не найдены. Выход"; exit_clear; }
        if [[ "$usr_count" -gt 1 ]]; then
            echo_tty $'\nВыберите пользователей для конфигурирования:'
            for ((i=1; i<=$usr_count; i++)); do
                echo_tty "  $i. $(echo "${user_list[$group_name]}" | sed -n "${i}p" )"
            done
            echo_tty $'\nДля выбора всех пользователей нажмите Enter'
            while true; do
                usr_range=$( read_question_select 'Введите номера выбранных пользователей (прим 1,2-10)' '\A^(([0-9]{1,3}((\-|\.\.)[0-9]{1,3})?([\,](?!$\Z)|(?![0-9])))+|)$\Z' )
                [[ "$usr_range" == '' ]] && { usr_list=${user_list[$group_name]}; break; }

                usr_list=''
                local numarr=( $( get_numrange_array "$usr_range") )
                for ((i=1; i<=$(echo -n "${user_list[$group_name]}" | grep -c '^'); i++)); do
                    printf '%s\n' "${numarr[@]}" | grep -Fxq "$i" && { usr_list=$(echo "$usr_list"; echo "${user_list[$group_name]}" | sed -n "${i}p" ); }
                done
                [[ "$usr_list" != '' ]] && break || echo_warn "Не выбран ни один пользователь!"
            done
            user_list[$group_name]=$( echo "$usr_list" | sed /^$/d )
        fi
        echo_tty -n $'\nВыбранные пользователи: '; echo_tty "$( get_val_print "$( echo ${user_list[$group_name]} )" )"

        opt_stand_nums=()
        [[ $switch == 1 ]] && { enable=1; state="${c_ok}включен"; }
        [[ $switch == 2 ]] && { enable=0; state="${c_error}выключен"; }
        for ((i=1; i<=$( echo -n "${user_list[$group_name]}" | grep -c '^' ); i++)); do
            user_name=$( echo "${user_list[$group_name]}" | sed -n "${i}p" )
            [[ $switch != 3 ]] && {
                run_cmd /noexit pve_api_request return_cmd PUT "/access/users/$user_name" enable=$enable || { echo_err "Ошибка: не удалось изменить enable для пользователя '$user_name'"; }
                echo_tty "$user_name : $state";
                continue
            }
            opt_stand_nums+=( "$user_name" )
        done

        if [[ $switch == 3 ]]; then
            local switch=0 val='' opt=''
            while true; do
                echo_tty "$( show_config passwd-change )"
                switch=$( read_question_select 'Выбранный пункт конфигурации' '^([0-9]+|)$' 0 2 )
                [[ "$switch" == 0 || "$switch" == '' ]] && break
                case "$switch" in
                    1) opt='access_pass_length';;
                    2) opt='access_pass_chars';;
                esac
                val=$( read_question_select "${config_base[_$opt]:-$opt}" )
                case "$switch" in
                    1) isdigit_check "$val" $var_pve_passwd_min 20 || { echo_err "Ошибка: допустимая длина паролей от $var_pve_passwd_min до 20"; continue; };;
                    2) isregex_check "[$val]" && ( config_base[access_pass_chars]="$val"; deploy_access_passwd test ) || { echo_err "Ошибка: '[$val]' не является регулярным выражением или или не захватывает достаточно символов для составления пароля"; continue; };;
                esac
                config_base["$opt"]=$val
            done
            deploy_access_passwd set
        fi
        opt_stand_nums=()
        echo_tty $'\n'"${c_success}Настройка завершена.${c_null} Выход"; return 0
    fi

    local stand_range='' stand_count=$(echo -n "${pool_list[$group_name]}" | grep -c '^') stand_list='' usr_list=''

    [[ "$stand_count" == 0 ]] && { echo_err "Ошибка: пулы стендов '$group_name' не найдены. Выход"; exit_clear; }
    if [[ "$stand_count" -gt 1 ]]; then
        echo_tty $'\nВыберите стеды для управления:'
        for ((i=1; i<=$stand_count; i++)); do
            echo_tty "  $i. $(echo "${pool_list[$group_name]}" | sed -n "${i}p" )"
        done
        echo_tty $'\nДля выбора всех стендов группы нажмите Enter'
        while true; do
            stand_range=$( read_question_select 'Введите номера выбранных стендов (прим 1,2-10)' '\A^(([0-9]{1,3}((\-|\.\.)[0-9]{1,3})?([\,](?!$\Z)|(?![0-9])))+|)$\Z' )
            stand_list=''
            usr_list=''
            [[ "$stand_range" == '' ]] && { stand_list=${pool_list[$group_name]}; usr_list=${user_list[$group_name]}; break; } 
            

            local numarr=( $( get_numrange_array "$stand_range" ) )
            for ((i=1; i<=$( echo -n "${pool_list[$group_name]}" | grep -c '^' ); i++)); do
                printf '%s\n' "${numarr[@]}" | grep -Fxq "$i" && {
                    local stand_name=$( echo -n "${pool_list[$group_name]}" | sed -n "${i}p" )
                    stand_list=$( echo "$stand_list"; echo "$stand_name" )
                    local j=1 path user
                    max_count=$( printf '%s\n' "${!acl_list[@]}" | sort -Vr | head -n 1 | grep -Po '^\d+' )
                    for ((j=0; j<=$max_count; j++)); do
                        path="${acl_list[$j,path]}"
                        [[ "$path" == "/pool/$stand_name" && "${acl_list[$j,type]}" == user ]] || continue
                        user="${acl_list[$j,ugid]}"
                        usr_list=$( echo "$usr_list"; echo "$user" )
                    done
                }
            done
            [[ "$stand_list" != '' ]] && break || echo_warn "Не выбран ни один стенд!"
        done

        stand_list=$( echo "$stand_list" | sed /^$/d )
        user_list[$group_name]=$( echo "$usr_list" | sed /^$/d )
        [[ "${pool_list[$group_name]}" == "$stand_list" ]] && local del_all=true
        pool_list[$group_name]=$stand_list
    else
        local del_all=true
    fi

    echo_tty -n $'\nВыбранные стенды: '; echo_tty "$( get_val_print "$( echo ${pool_list[$group_name]} )" )"

    local regex='(,|{)\s*\"{opt_name}\"\s*:\s*(\K[0-9]+|\"\K(?(?=\\").{2}|[^"])+)'

    local vm_snap_name='' vm_snap_description='' vm_cmd_arg='' pool_info vmid_list vmname_list vmid vm_node_list='' vm_status_list=''  vm_type_list='' vm_is_template_list='' vm_node='' vm_status='' vm_type='' vm_is_template=''

    [[ "$switch" == 4 || "$switch" == 5 ]] && manage_bulk_vm_power --init

    [[ "$switch" -ge 6 ]] && vm_snap_name='Start'
    [[ "$switch" -ge 7 && "$switch" -le 9 ]] && {
        echo_info $'\n'"Имя снапшота может состоять из симолов ${c_value}A-Z a-z - _${c_info}. Первый симол всегда буква"
        vm_snap_name=$( read_question_select 'Введите имя снапшота' '^[a-zA-Z][\w\-]+$' )
    }
    [[ "$switch" == 7 ]] && vm_snap_description="$( read_question_select $'Описание для снапшота' )"

    if [[ $switch -ge 4 && $switch -le 9 ]]; then
        read_question $'\nВы действительно хотите продолжить?' || return 0
        local status name cmd_str vm_poweroff=false vm_snap_state=true vm_poweroff_answer=true
        case $switch in
                    7) cmd_str="create /nodes/{node}/{type}/{vmid}/snapshot --snapname '{snap_name}' --description '{snap_descr}'{vm_state}";;
                    6|8) cmd_str="create /nodes/{node}/{type}/{vmid}/snapshot/{snap_name}/rollback";;
                    9) cmd_str="delete /nodes/{node}/{type}/{vmid}/snapshot/{snap_name}";;
        esac
        for ((i=1; i<=$( echo -n "${pool_list[$group_name]}" | grep -c '^' ); i++)); do
            echo_tty
            pool_name=$( echo "${pool_list[$group_name]}" | sed -n "${i}p" )
            pve_api_request pool_info GET "/pools/$pool_name" || { echo_err "Ошибка: не удалось получить информацию об стенде '$pool_name'"; exit_clear; }
            vmid_list=$( echo "$pool_info" | grep -Po "${regex/\{opt_name\}/vmid}" )
            vmname_list=$( echo "$pool_info" | grep -Po "${regex/\{opt_name\}/name}" )
            vm_node_list=$( echo "$pool_info" | grep -Po "${regex/\{opt_name\}/node}" )
            vm_status_list=$( echo "$pool_info" | grep -Po "${regex/\{opt_name\}/status}" )
            vm_type_list=$( echo "$pool_info" | grep -Po "${regex/\{opt_name\}/type}" )
            vm_is_template_list=$( echo "$pool_info" | grep -Po "${regex/\{opt_name\}/template}" )


            for ((j=1; j<=$( echo -n "$vmid_list" | grep -c '^' ); j++)); do
                vmid=$( echo "$vmid_list" | sed -n "${j}p" )
                name=$( echo "$vmname_list" | sed -n "${j}p" )
                vm_node=$( echo "$vm_node_list" | sed -n "${j}p" )
                vm_status=$( echo "$vm_status_list" | sed -n "${j}p" )
                vm_type=$( echo "$vm_type_list" | sed -n "${j}p" )
                is_template=$( echo "$vm_is_template_list" | sed -n "${j}p" )
                
                [[ "$is_template" == '1' || "$vm_type" != 'qemu' ]] && continue
                [[ "$switch" == 4 || "$switch" == 5 ]] && {
                    manage_bulk_vm_power --add "$vm_node" "$vmid"
                    continue
                }
                [[ "$switch" == 7 && "$vm_status" == running ]] && {
                    $vm_poweroff_answer && {
                        vm_poweroff=$( read_question "Машина ${c_ok}$name${c_null} (${c_info}$vmid${c_null}) стенда ${c_value}$pool_name${c_null} включена. При создании снапшота рекомендуется выключить ВМ. "$'\nВыключать виртуальные машины перед созданием снапшота?' && echo true || echo false)
                        ! $vm_poweroff && { read_question $'\n'"Сохранять включенное состояние виртуальных машин? Иначе будут сохранены только данные на дисках"$'\n'"Сохранять VM state?" || vm_snap_state=false; }
                        echo_tty 
                        vm_poweroff_answer=false
                    }
                    $vm_poweroff && run_cmd "pvesh create /nodes/$vm_node/stopall --vms '$vmid' --timeout '30' --force-stop '1'"
                }
                vm_cmd_arg=" --vmstate '$vm_snap_state'"
                [[ "$vm_type" != 'qemu' ]] && vm_cmd_arg=''
                status=$( run_cmd /noexit "pvesh $(echo "$cmd_str" | sed "s/{node}/$vm_node/;s/{vmid}/$vmid/;s/{vm_state}/$vm_cmd_arg/;s/{type}/$vm_type/;s/{snap_name}/$vm_snap_name/;s/{snap_descr}/$vm_snap_description/" ) 2>&1" ) && {
                    echo_ok "Стенд ${c_value}$pool_name${c_null} машина ${c_ok}$name${c_null} (${c_info}$vmid${c_null})"
                    continue
                }

                echo "$status" | grep -Pq $'^snapshot feature is not available$' && echo_err "Ошибка: ВМ $name ($vmid) стенда $pool_name: хранилище ВМ не поддерживает создание снапшота!" && continue
                echo "$status" | grep -Pq $'^Configuration file \'[^\']+\' does not exist$' && echo_err "Ошибка: ВМ $name ($vmid) стенда $pool_name не существует!" && continue
                echo "$status" | grep -Pq $'^snapshot \'[^\']+\' does not exist$' && echo_err "Ошибка: Снапшот ВМ $name ($vmid) стенда $pool_name не существует!" && continue
                echo "$status" | grep -Pq $'^snapshot name \'[^\']+\' already used$' && echo_err "Ошибка: Снапшот ВМ $name ($vmid) стенда $pool_name уже существует!" && continue
                echo_err "Необработанная ошибка: ВМ $name ($vmid), стенд $pool_name:"$'\n'$status; exit_clear;
            done
        done
        [[ "$switch" == 4 || "$switch" == 5 ]] && manage_bulk_vm_power --stop-vms
        [[ "$switch" == 4 ]] && manage_bulk_vm_power --start-vms
    fi

    if [[ $switch == 10 ]]; then

        echo_tty -n $'Выбранные пользователи: '; get_val_print "$(echo ${user_list[$group_name]} )"
        read_question $'\nВы действительно хотите продолжить?' || return 0

        function make_node_ifs_info {
            local -n ifaces_info="ifaces_info_$(echo -n "$vm_nodes" | grep -c '^')"
            local -n deny_ifaces="deny_ifaces_$(echo -n "$vm_nodes" | grep -c '^')"
            local bridge_ports vm_node=$( echo "$vm_nodes" | sed -n "$(echo -n "$vm_nodes" | grep -c '^')p" )

            jq_data_to_array /nodes/$vm_node/network ifaces_info
            local i=1
            max_count=$( printf '%s\n' "${!ifaces_info[@]}" | sort -Vr | head -n 1 | grep -Po '^\d+' )
            for ((i=0; i<=$max_count; i++)); do
                bridge_ports="${ifaces_info[$i,bridge_ports]}"
                ifname="${ifaces_info[$i,iface]}"
                [[ "$bridge_ports" != '' && "$( get_numtable_val ifaces_info "iface=$bridge_ports" vlan-raw-device )" == '' || "${ifaces_info[$i,address]}" != '' \
                    || "${ifaces_info[$i,address6]}" != '' ]] && {
                        deny_ifaces+=" $ifname $bridge_ports"
                }
            done
        }
        echo_tty

        function delete_if {
            [[ "$1" == '' || "$2" == '' ]] && exit_clear
            run_cmd /noexit pve_api_request "''" DELETE "/nodes/$vm_node/network/$2";
            [[ $? =~ ^0$|^244$ ]] || { echo_err "Ошибка: не удалось удалить сетевой интерфейс '$2'"; exit_clear; }
            echo_ok "Стенд ${c_value}$1${c_null}: удален сетевой интерфейс ${c_ok}$2${c_null}${3:+ ($3)}"        
            deny_ifaces+=" $2"
        }

        local ifname vm_nodes='' vm_netifs depend_if if_desc k restart_network=false vm_protection=0 vm_del_protection_answer=''
        for ((i=1; i<=$( echo -n "${pool_list[$group_name]}" | grep -c '^' ); i++)); do
            echo_tty
            pool_name=$( echo "${pool_list[$group_name]}" | sed -n "${i}p" )
            pve_api_request pool_info GET "/pools/$pool_name" || { echo_err "Ошибка: не удалось получить информацию об стенде '$pool_name'"; exit_clear; }
            vmid_list=$( echo "$pool_info" | grep -Po "${regex/\{opt_name\}/vmid}" )
            vmname_list=$( echo "$pool_info" | grep -Po "${regex/\{opt_name\}/name}" )
            vm_node_list=$( echo "$pool_info" | grep -Po "${regex/\{opt_name\}/node}" )
            vm_status_list=$( echo "$pool_info" | grep -Po "${regex/\{opt_name\}/status}" )
            vm_type_list=$( echo "$pool_info" | grep -Po "${regex/\{opt_name\}/type}" )
            vm_is_template_list=$( echo "$pool_info" | grep -Po "${regex/\{opt_name\}/template}" )
            vm_nodes=$( echo "$vm_nodes"$'\n'"$vm_node_list" | awk '!seen[$0]++ && NF' )
            [[ "$vm_nodes" == '' ]] && break
            [[ ! -v "ifaces_info_$( echo -n "$vm_nodes" | grep -c '^')" ]] \
                && local -A "ifaces_info_$(echo -n "$vm_nodes" | grep -c '^')" && local "deny_ifaces_$( echo -n "$vm_nodes" | grep -c '^' )" && make_node_ifs_info


            for ((j=1; j<=$( echo -n "$vmid_list" | grep -c '^' ); j++)); do
                vmid=$( echo -n "$vmid_list" | sed -n "${j}p" )
                name=$( echo -n "$vmname_list" | sed -n "${j}p" )
                vm_node=$( echo -n "$vm_node_list" | sed -n "${j}p" )
                vm_status=$( echo -n "$vm_status_list" | sed -n "${j}p" )
                vm_type=$( echo -n "$vm_type_list" | sed -n "${j}p" )
                is_template=$( echo -n "$vm_is_template_list" | sed -n "${j}p" )

                local -n ifaces_info="ifaces_info_$(echo -n "$vm_nodes" | awk -v s="$vm_node" '$0=s{print NR;exit}')"
                local -n deny_ifaces="deny_ifaces_$(echo -n "$vm_nodes" | awk -v s="$vm_node" '$0=s{print NR;exit}')"

                pve_api_request vm_netifs GET "/nodes/$vm_node/$vm_type/$vmid/config" || { 
                    [[ $? == 244 ]] && { echo_warn "Предупреждение: Машина ${c_ok}$name${c_warn} (${c_info}$vmid${c_warn}) уже была удалена!"; continue; }
                    echo_err "Ошибка: не удалось получить информацию о ВМ $name ($vmid)"; exit_clear; 
                }
                vm_protection="$( echo -n "$vm_netifs" | grep -Po '(,|{)\s*"protection"\s*:\s*\"?\K\d' )"
                vm_netifs=$( echo -n "$vm_netifs" | grep -Po '(,|{)\s*\"net[0-9]+\"\s*:\s*(\".*?bridge=\K\w+)' | uniq )

                for ((k=1; k<=$( echo -n "$vm_netifs" | grep -c '^' ); k++)); do
                    ifname=$( echo -n "$vm_netifs" | sed -n "${k}p" )
                    echo -n "$deny_ifaces" | grep -Pq '(?<=^| )'$ifname'(?=$| )' && continue
                    [[ "$( get_numtable_val ifaces_info "iface=$ifname" iface )" == '' ]] && { deny_ifaces+=" $ifname"; continue; }
                    if_desc=$( get_numtable_val ifaces_info "iface=$ifname" comments )
                    if_desc=$( printf '%b\n' "$if_desc" )
                    depend_if=$( get_numtable_val ifaces_info "vlan-raw-device=$ifname" iface )
                    [[ "$depend_if" != '' ]] && ! echo -n "$deny_ifaces" | grep -Pq '(?<=^| )'$ifname'(?=$| )' && delete_if "$pool_name" "$depend_if"
                    delete_if "$pool_name" "$ifname" "$if_desc"
                    restart_network=true
                done
                [[ "$vm_protection" == '1' ]] && {
                    [[ "$vm_del_protection_answer" == '' ]] && vm_del_protection_answer=$( read_question "Машина ${c_ok}$name${c_null} (${c_info}$vmid${c_null}) стенда ${c_value}$pool_name${c_null}: включена защита от удаления"$'\n'"Продолжить удаление стендов?" && echo 1 || exit_clear )
                    run_cmd pve_api_request return_cmd PUT "/nodes/$vm_node/$vm_type/$vmid/config" "protection=0"
                }

                [[ "$vm_status" == 'running' && "$vm_type" == 'qemu' ]] && run_cmd "pvesh create /nodes/$vm_node/$vm_type/$vmid/status/stop --skiplock '1' --timeout '0'"
                vm_cmd_arg="--skiplock '1' --purge '1'"
                [[ "$vm_type" != 'qemu' ]] && vm_cmd_arg="--force '1'"
                run_cmd /noexit "pvesh delete '/nodes/$vm_node/$vm_type/$vmid' $vm_cmd_arg"
                [[ $? =~ ^0$|^2$ ]] && echo_ok "Стенд ${c_value}$pool_name${c_null}: удалена машина ${c_ok}$name${c_null} (${c_info}$vmid${c_null})" \
                    || { echo_err "Ошибка: не удалось удалить ВМ '$vmid' стенда '$pool_name'"; exit_clear; }
            done
            local storages=$( echo "$pool_info" | grep -Po "${regex/\{opt_name\}/storage}" | awk 'NR>1{printf " "}{printf $0}' )
            [[ "$storages" != '' ]] && { run_cmd /noexit pve_api_request "''" PUT "/pools/$pool_name delete=1 'storage=$storages'"
                [[ $? =~ ^0$|^244$ ]] || { echo_err "Ошибка: не удалось удалить привязку хранилищ от пула стенда '$pool_name'"; exit_clear; } }
            run_cmd /noexit pve_api_request "''" DELETE "/pools/$pool_name"; [[ $? =~ ^0$|^244$ ]] || { echo_err "Ошибка: не удалось удалить пул стенда '$pool_name'"; exit_clear; }
            echo_ok "Стенд ${c_value}$pool_name${c_null}: пул удален"
        done

        for ((i=1; i<=$( echo -n "${user_list[$group_name]}" | grep -c '^' ); i++)); do
            user_name=$( echo -n "${user_list[$group_name]}" | sed -n "${i}p" )
            
            run_cmd /noexit pve_api_request return_cmd DELETE "/access/users/$user_name" \
                && echo_ok "Пользователь ${c_value}$user_name${c_null} удален" \
                || { echo_err "Ошибка: не удалось удалить пользователя '$user_name' стенда '$pool_name'"; exit_clear; }
        done

        local roles_list_after 
        local -A list_roles
        pve_api_request roles_list_after GET /access/acl || { echo_err "Ошибка: не удалось получить список ролей через API"; exit_clear; }
        roles_list_after="$( echo -n "$roles_list_after" | grep -Po '(,|{)"roleid":"\K[^"]+' | sort -u )"
        jq_data_to_array /access/roles list_roles

        for role in $( printf '%s\n' "${!acl_list[@]}" | grep -Pox '\d+,roleid' ); do
            echo -n "$roles_list_after" | grep -Fxq -- "${acl_list[$role]}" || {
                [[ "$( get_numtable_val list_roles "roleid=${acl_list[$role]}" special )" == 0 ]] || continue
                run_cmd /noexit pve_api_request "''" DELETE "/access/roles/${acl_list[$role]}"; [[ $? =~ ^0$|^244$ ]] || { echo_err "Ошибка: не удалось удалить access роль '${acl_list[$role]}'. Выход"; exit_clear; }
                echo_ok "Роль ${c_value}${acl_list[$role]}${c_null} удалена"
                roles_list_after+=$'\n'${acl_list[$role]}
            }
        done

        [[ "$del_all" == true ]] && { 
            run_cmd /noexit pve_api_request "''" DELETE "/access/groups/$group_name"; [[ $? =~ ^0$|^244$ ]] || { echo_err "Ошибка: не удалось удалить access группу стендов '$group_name'. Выход"; exit_clear; }
            echo_ok "Служебная группа ${c_value}$group_name${c_null} удалена"
        }

        $restart_network && {
            for pve_host in $vm_nodes; do
                run_cmd "pvesh set '/nodes/$pve_host/network'"
                echo_ok "Перезагрузка сети хоста ${c_val}$pve_host"
            done
        }
    fi

    echo_tty $'\n'"${c_ok}Настройка завершена.${c_null}"
}


conf_files=()
_opt_show_help='Вывод в терминал справки по команде, а так же примененных значений конфигурации и выход'
opt_show_help=false
_opt_show_config='Вывод в терминал (или файл) примененных значений конфигурации и выход'
opt_show_config=false

_opt_silent_install='Произвести установку стенда в "тихом" режиме без интерактивного ввода'
opt_silent_install=false
_opt_silent_control=$'Управление настройками уже развернутых стендов (применение настроек, управление пользователями).\n\tБез интерактивного ввода (через аргументы командной строки и конфигурационные файлы)'
opt_silent_control=false
_opt_verbose='Включить подробный вывод сообщений (verbose mode)'
opt_verbose=false
_opt_zero_vms=$'Очищает конфигурацию ВМ. Срабатывает при применении конфигурации из файла'
opt_zero_vms=false
_opt_stand_nums='Кол-во разворачиваемых стендов. Числа от 0 до 99. Списком, напр.: 1-6,8'
opt_stand_nums=()
_opt_rm_tmpfs='Не удалять временный раздел после установки'
opt_rm_tmpfs=true
# состояние скрипта, при котором запрос ан удаление tmpfs бессмыслен (в меню и пр)
opt_not_tmpfs=true
_opt_dry_run='Запустить установку в тестовом режиме, без реальных изменений'
opt_dry_run=false

_opt_sel_var='Выбор варианта установки стендов'
opt_sel_var=0

# список скачанных файлов
declare -A list_url_files

# Обработка аргуметов командой строки
switch_action=0
iteration=1
i=0
while [ $# != 0 ]; do
    ((i++))
    case $iteration in
        1)  case "${!i}" in
                -z|--clear-vmconfig)    opt_zero_vms=true; set -- "${@:1:i-1}" "${@:i+1}"; ((i--));;
                -v|--verbose)           opt_verbose=true; set -- "${@:1:i-1}" "${@:i+1}"; ((i--));;
            esac;;
        2)  if [[ "${!i}" == '-c' || "${!i}" == '--config' ]]; then
            ((i++)); set_configfile "${!i}"; set -- "${@:1:i-2}" "${@:i+1}"; ((i-=2)); fi;;
        *)  case "$1" in
                \?|-\?|/\?|-h|/h|--help) opt_show_help=true;;
                -sh|--show-config) opt_show_config=true
                    [[ "$2" =~ ^[^-].* ]] && conf_files+=("$2") && shift;;
                -n|--stand-num)         check_arg "$2"; set_standnum "$2"; shift;;
                -var|--set-var-num)     check_arg "$2"; set_varnum "$2"; shift;;
                -si|--silent-install)   opt_silent_install=true; switch_action=1;;
                --dry-run)              opt_dry_run=true;;
                -vmbr|--wan-bridge)     check_arg "$2"; config_base[inet_bridge]="$2"; shift;;
                -vmid|--start-vm-id)    check_arg "$2"; config_base[start_vmid]="$2"; shift;;
                -dir|--mk-tmpfs-dir)    check_arg "$2"; config_base[mk_tmpfs_imgdir]="$2"; shift;;
                -norm|--no-clear-tmpfs) opt_rm_tmpfs=false;;
                -st|--storage)          check_arg "$2"; config_base[storage]="$2"; shift;;
                -pn|--pool-name)        check_arg "$2"; config_base[pool_name]="$2"; shift;;
                -snap|--take-snapshots) check_arg "$2"; config_base[take_snapshots]="$2"; shift;;
                -inst-start-vms|--run-vm-after-installation) check_arg "$2"; config_base[run_vm_after_installation]="$2"; shift;;
                -acl|--access-create)   check_arg "$2"; config_base[access_create]="$2"; shift;;
                -u|--user-name)         check_arg "$2"; config_base[access_user_name]="$2"; shift;;
                -l|--pass-length)       check_arg "$2"; config_base[access_pass_length]="$2"; shift;;
                -char|--pass-chars)     check_arg "$2"; config_base[access_pass_chars]="$2"; shift;;
                -sctl|--silent-control) opt_silent_control=true;;
                -api|--pve-api-url) check_arg "$2"; config_base[pve_api_url]="$2"; shift;;
                *) echo_err "Ошибка: некорректный аргумент: '$1'"; opt_show_help=true;;
            esac
            shift;;
    esac
    if [[ $i -ge $# ]]; then ((iteration++)); i=0; fi
done

silent_mode=$opt_silent_install || $opt_silent_control

if $opt_show_help; then show_help; exit; fi

check_config base-check

if $opt_show_config; then
    terraform_config_vars
    [ -t 1 ] && show_config detailed || show_config detailed | sed -r 's/\x1B\[([0-9]{1,3}(;[0-9]{1,2};?)?)?[mGK]//g;s/\r//g'
    for file in "${conf_files[@]}"; do
        show_config detailed | sed -r 's/\x1B\[([0-9]{1,3}(;[0-9]{1,2};?)?)?[mGK]//g;s/\r//g' > $file
    done
    exit_clear 0
fi

echo_tty $'\n'"${c_ok}Подождите, идет проверка конфигурации...${c_null}"$'\n'
terraform_config_vars; check_config check-only;

$silent_mode && {
    case $switch_action in
        1) install_stands;;
        2) manage_stands;;
        *) echo_warn 'Функционал в процессе разработки и пока недоступен. Выход'; exit_clear;;
    esac
}

_exit=false
while ! $silent_mode; do
    $silent_mode || switch_action=$(read_question_select $'\nДействие: 1 - Развертывание стендов, 2 - Управление стендами' '^([1-2]|)$' )

    case $switch_action in
        1) _exit=false; install_stands || exit_clear 0;;
        2) _exit=false; manage_stands || exit_clear 0;;
        '') $_exit && exit_clear 0; _exit=true;;
        *) echo_warn 'Функционал в процессе разработки и пока недоступен. Выход'; exit_clear 0;;
    esac
done

configure_clear
