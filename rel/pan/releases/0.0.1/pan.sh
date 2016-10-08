#!/bin/sh

if [ -n "${EXRM_INIT_TRACE}" ]; then
    set -x
fi

SCRIPT_DIR="$(dirname "$0")"
RELEASE_ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REL_NAME="pan"
RELEASES_DIR="$RELEASE_ROOT_DIR/releases"
REL_VSN=$(cat "$RELEASES_DIR"/start_erl.data | cut -d' ' -f2)
ERTS_VSN=$(cat "$RELEASES_DIR"/start_erl.data | cut -d' ' -f1)
REL_DIR="$RELEASES_DIR/$REL_VSN"
REL_LIB_DIR="$RELEASE_ROOT_DIR/lib"
ERL_OPTS=" ${ERL_OPTS}"
CONFORM_OPTS=""
PIPE_DIR="$RELEASE_ROOT_DIR/tmp/erl_pipes/pan/"
ERTS_DIR=""
ROOTDIR=""

GENERATED_CONFIG_DIR="${RELEASE_ROOT_DIR}/running-config"
# Check for $RELEASE_MUTABLE_DIR
if [ -n "${RELEASE_MUTABLE_DIR}" ]; then
    PIPE_DIR="${RELEASE_MUTABLE_DIR}/erl_pipes/"
    RUNNER_LOG_DIR="${RUNNER_LOG_DIR:-${RELEASE_MUTABLE_DIR}/log}"
    GENERATED_CONFIG_DIR="${RELEASE_MUTABLE_DIR}/running-config"
fi

RUNNER_LOG_DIR="${RUNNER_LOG_DIR:-$RELEASE_ROOT_DIR/log}"

find_erts_dir() {
    __erts_dir="$RELEASE_ROOT_DIR/erts-$ERTS_VSN"
    if [ -d "$__erts_dir" ]; then
        ERTS_DIR="$__erts_dir";
        ROOTDIR="$RELEASE_ROOT_DIR"
    else
        __erl="$(which erl)"
        __code="io:format(\"~s\", [code:root_dir()])."
        __erl_root="$("$__erl" -noshell -eval "$__code" -s init stop)"
        ERTS_DIR=$(ls -d $__erl_root/erts-* | sort -t '.' -k 1,1 -k 2,2 -k 3,3 -k 4,4 -k 5,5 -g | tail -n 1)
        ROOTDIR="$__erl_root"
    fi
}

# Connect to a remote node
relx_rem_sh() {
    # Generate a unique id used to allow multiple remsh to the same node
    # transparently
    id="remsh$(relx_gen_id)-${NAME}"

    # Get the node's ticktime so that we use the same thing
    TICKTIME="$(relx_nodetool rpcterms net_kernel get_net_ticktime)"

    # Setup Erlang remote shell command to control node
    #exec "$ERTS_DIR/bin/erl" "$NAME_TYPE" "$id" -remsh "$NAME" -boot start_clean \
         #-setcookie "$COOKIE" -kernel net_ticktime "$TICKTIME"

    # Setup Elixir remote shell command to control node
    exec "$BINDIR/erl" \
        -pa "$ROOTDIR"/lib/*/ebin -pa "$CONSOLIDATED_DIR" \
        -hidden -noshell \
        -boot start_clean -boot_var ERTS_LIB_DIR "$ERTS_LIB_DIR" \
        -kernel net_ticktime "$TICKTIME" \
        -user Elixir.IEx.CLI "$NAME_TYPE" "$id" -setcookie "$COOKIE" \
        -extra --no-halt +iex -"$NAME_TYPE" "$id" --cookie "$COOKIE" --remsh "$NAME"
}

# Generate a random id
relx_gen_id() {
    od -t x4 /dev/urandom | head -n1 | cut -d ' ' -f2
}

# Control a node - set PEERNAME to control a peer node
relx_nodetool() {
    command="$1"; shift
    name=${PEERNAME:-$NAME}
    "$BINDIR/escript" "$ROOTDIR/bin/nodetool" "$NAME_TYPE" "$name" \
                                 -setcookie "$COOKIE" "$command" "$@"
}

# Run an escript in the node's environment
relx_escript() {
    shift; __scriptpath="$1"; shift
    export RELEASE_ROOT_DIR
    "$BINDIR/escript" "$ROOTDIR/$__scriptpath" $@
}

# Output a start command for the last argument of run_erl
relx_start_command() {
    printf "exec \"%s\" \"%s\"" "$RELEASE_ROOT_DIR/bin/$REL_NAME" \
           "$START_OPTION"
}

# Convert .conf to sys.config using conform escript
generate_config() {
    __schema_file="$REL_DIR/$REL_NAME.schema.exs"
    if [ -z "$RELEASE_CONFIG_FILE" ]; then
        __conform_file="$RELEASE_CONFIG_DIR/$REL_NAME.conf"
    else
        if [ -r "$RELEASE_CONFIG_FILE" ]; then
            __conform_file="$RELEASE_CONFIG_FILE"
        else
            echo "$RELEASE_CONFIG_FILE not found"
            exit 1
        fi
    fi
    if [ -f "$__schema_file" ]; then
        if [ -f "$__conform_file" ]; then
            __running_conf="$GENERATED_CONFIG_DIR/$REL_NAME.conf"
            CONFORM_OPTS="-conform_schema ${__schema_file} -conform_config ${__conform_file} -running_conf ${__running_conf}"

            # always copy release-config to running-config
            echo "copying $__conform_file to $__running_conf ..."
            cp "$__conform_file" "$__running_conf"
            __conform_file="$__running_conf"

            echo "using $__conform_file to populate \"$GENERATED_CONFIG_DIR\"."
            __conform="$REL_DIR/conform"
            # Handle the case where the current version did not bundle conform in the release
            if [ ! -f "$__conform" ]; then
                __conform="$ROOTDIR/bin/conform"
            fi
            result="$("$BINDIR/escript" "$__conform" --conf "$__conform_file" --schema "$__schema_file" --config "$RELEASE_SYS_CONFIG" --output-dir "$GENERATED_CONFIG_DIR")"
            exit_status="$?"
            if [ "$exit_status" -ne 0 ]; then
                exit "$exit_status"
            fi
            if [ ! -r "${GENERATED_CONFIG_DIR}/sys.config" ]; then
                echo "conform succeeded, but not sys.config generated at \"${GENERATED_CONFIG_DIR}/sys.config\"."
                exit 1
            fi
        else
            echo "$__conform_file not found in $RELEASE_CONFIG_DIR"
            exit 1
        fi
    else
        cp $RELEASE_SYS_CONFIG "$GENERATED_CONFIG_DIR/sys.config"
    fi
    if [ ! -f "$VMARGS_PATH" ]; then
        cp "$RELEASE_CONFIG_DIR/vm.args" "$GENERATED_CONFIG_DIR/vm.args"
        VMARGS_PATH="$GENERATED_CONFIG_DIR/vm.args"
    fi
}

# Make directory for mutable configs exists
mkdir -pv "$GENERATED_CONFIG_DIR"

# Use configs from environment if defined, otherwise releases/VSN
if [ -z "$RELEASE_CONFIG_DIR" ]; then
    RELEASE_CONFIG_DIR=$REL_DIR
fi

SYS_CONFIG="$GENERATED_CONFIG_DIR/sys.config"
RELEASE_SYS_CONFIG="$RELEASE_CONFIG_DIR/sys.config"
if [ -z "$VMARGS_PATH" ]; then
  VMARGS_PATH="$GENERATED_CONFIG_DIR/vm.args"
fi

# If first run, take dafault sys.config and vm.args
if [ ! -f "$SYS_CONFIG" ]; then
    cp $RELEASE_SYS_CONFIG "$GENERATED_CONFIG_DIR/sys.config"
fi
if [ ! -f "$VMARGS_PATH" ]; then
    cp "$RELEASE_CONFIG_DIR/vm.args" "$GENERATED_CONFIG_DIR/vm.args"
fi

if [ $RELX_REPLACE_OS_VARS ]; then
    awk '{while(match($0,"[$]{[^}]*}")) {var=substr($0,RSTART+2,RLENGTH -3);gsub("[$]{"var"}",ENVIRON[var])}}1' < $VMARGS_PATH > $VMARGS_PATH.2.config
    VMARGS_PATH=$VMARGS_PATH.2.config
fi

# Make sure log directory exists
mkdir -p "$RUNNER_LOG_DIR"

# Make sure the current user has write permission
if ! [ -w $RUNNER_LOG_DIR ] ; then
    echo "Unable to write to $RUNNER_LOG_DIR. Quitting."
    exit 1
fi

if [ $RELX_REPLACE_OS_VARS ]; then
    awk '{while(match($0,"[$]{[^}]*}")) {var=substr($0,RSTART+2,RLENGTH -3);gsub("[$]{"var"}",ENVIRON[var])}}1' < $SYS_CONFIG > $SYS_CONFIG.2.config
    SYS_CONFIG=$SYS_CONFIG.2.config
fi

# Extract the target node name from node.args
NAME_ARG=$(egrep '^-s?name' "$VMARGS_PATH")
if [ -z "$NAME_ARG" ]; then
    echo "vm.args needs to have either -name or -sname parameter."
    exit 1
fi

# Extract the name type and name from the NAME_ARG for REMSH
NAME_TYPE="$(echo "$NAME_ARG" | awk '{print $1}')"
NAME="$(echo "$NAME_ARG" | awk '{print $2}')"

# User can specify an sname without @hostname
# This will fail when creating remote shell
# So here we check for @ and add @hostname if missing
case $NAME in
    *@*)
        # Nothing to do
        ;;
    *)
        # Add @hostname
        case $NAME_TYPE in
            -sname)
                NAME=$NAME@`hostname -s`
                ;;
            -name)
                NAME=$NAME@`hostname -f`
                ;;
        esac
        ;;
esac

PIPE_DIR="${PIPE_DIR:-/tmp/erl_pipes/$NAME/}"

# Extract the target cookie
COOKIE_ARG="$(grep '^-setcookie' "$VMARGS_PATH")"
if [ -z "$COOKIE_ARG" ]; then
    echo "vm.args needs to have a -setcookie parameter."
    exit 1
fi

# Extract cookie name from COOKIE_ARG
COOKIE="$(echo "$COOKIE_ARG" | awk '{print $2}')"

find_erts_dir
export ROOTDIR="$RELEASE_ROOT_DIR"
export BINDIR="$ERTS_DIR/bin"
export EMU="beam"
export PROGNAME="erl"
export LD_LIBRARY_PATH="$ERTS_DIR/lib:$LD_LIBRARY_PATH"
ERTS_LIB_DIR="$ERTS_DIR/../lib"
CONSOLIDATED_DIR="$ROOTDIR/lib/${REL_NAME}-${REL_VSN}/consolidated"

cd "$ROOTDIR"

# Check the first argument for instructions
case "$1" in
    start|start_boot)
        # Make sure the config is generated first
        generate_config
        # Make sure there is not already a node running
        #RES=`$NODETOOL ping`
        #if [ "$RES" = "pong" ]; then
        #    echo "Node is already running!"
        #    exit 1
        #fi
        # Save this for later
        CMD="$1"
        case "$1" in
            start)
                shift
                START_OPTION="console"
                HEART_OPTION="start"
                ;;
            start_boot)
                shift
                START_OPTION="console_boot"
                HEART_OPTION="start_boot"
                ;;
        esac
        RUN_PARAM="$@"

        # Set arguments for the heart command
        set -- "$SCRIPT_DIR/$REL_NAME" "$HEART_OPTION"
        [ "$RUN_PARAM" ] && set -- "$@" "$RUN_PARAM"

        # Export the HEART_COMMAND
        HEART_COMMAND="$RELEASE_ROOT_DIR/bin/$REL_NAME $CMD"
        export HEART_COMMAND

        mkdir -p "$PIPE_DIR"

        # Make sure the current user has write permission
        if ! [ -w $PIPE_DIR ] ; then
            echo "Unable to write to $PIPE_DIR. Quitting."
            exit 1
        fi

        "$BINDIR/run_erl" -daemon "$PIPE_DIR" "$RUNNER_LOG_DIR" \
                          "$(relx_start_command)"
        ;;

    stop)
        # Wait for the node to completely stop...
        case $(uname -s) in
            Linux|Darwin|FreeBSD|DragonFly|NetBSD|OpenBSD)
                # PID COMMAND
                PID=$(ps ax -o pid= -o command=|
                      grep "$RELEASE_ROOT_DIR/.*/[b]eam"|awk '{print $1}')
                ;;
            SunOS)
                # PID COMMAND
                PID=$(ps -ef -o pid= -o args=|
                      grep "$RELEASE_ROOT_DIR/.*/[b]eam"|awk '{print $1}')
                ;;
            CYGWIN*)
                # UID PID PPID TTY STIME COMMAND
                PID=$(ps -efw|grep "$RELEASE_ROOT_DIR/.*/[b]eam"|awk '{print $2}')
                ;;
        esac
        relx_nodetool "stop"
        exit_status=$?
        if [ "$exit_status" -ne 0 ]; then
            exit $exit_status
        fi
        # ensuring PID is not empty
        if [ -z "$PID" ]; then
            exit 0
        fi
        while $(kill -0 "$PID" 2>/dev/null);
        do
            sleep 1
        done
        ;;

    restart)
        # Make sure the config is generated first
        generate_config
        ## Restart the VM without exiting the process
        relx_nodetool "restart"
        exit_status=$?
        if [ "$exit_status" -ne 0 ]; then
            exit $exit_status
        fi
        ;;

    reboot)
        # Make sure the config is generated first
        generate_config
        ## Restart the VM completely (uses heart to restart it)
        relx_nodetool "reboot"
        exit_status=$?
        if [ "$exit_status" -ne 0 ]; then
            exit $exit_status
        fi
        ;;

    ping)
        ## See if the VM is alive
        relx_nodetool "ping"
        exit_status=$?
        if [ "$exit_status" -ne 0 ]; then
            exit $exit_status
        fi
        ;;

    pingpeer)
        PEERNAME=$2 relx_nodetool "ping"
        exit_status=$?
        if [ "$exit_status" -ne 0 ]; then
            exit $exit_status
        fi
        ;;

    escript)
        # Make sure the config is generated first
        generate_config
        ## Run an escript under the node's environment
        relx_escript $@
        exit_status=$?
        if [ "$exit_status" -ne 0 ]; then
            exit $exit_status
        fi
        ;;

    rpc)
        ## Execute a command in MFA format on the remote node
        if [ -z "$3" ]; then
            echo "RPC requires module, function, and a string of the arguments to be evaluated."
            echo "The argument string must evaluate to a valid Erlang term."
            echo "Examples: rpc calendar valid_date \"{2013,3,12}.\""
            echo "          rpc erlang now"
            exit 1
        fi
        if [ -z "$4" ]; then
            relx_nodetool "rpcterms" "$2" "$3"
        else
            module="$2"
            function="$3"
            shift 3
            args=$@
            relx_nodetool "rpcterms" "$module" "$function" "$args"
        fi
        exit_status="$?"
        if [ "$exit_status" -ne 0 ]; then
            exit $exit_status
        fi
        ;;

    attach)
        # Make sure a node IS running
        relx_nodetool "ping" > /dev/null
        exit_status=$?
        if [ "$exit_status" -ne 0 ]; then
            echo "Node is not running!"
            exit $exit_status
        fi

        shift
        exec "$BINDIR/to_erl" "$PIPE_DIR"
        ;;

    remote_console)
        # Make sure a node IS running
        relx_nodetool "ping" > /dev/null
        exit_status=$?
        if [ "$exit_status" -ne 0 ]; then
            echo "Node is not running!"
            exit $exit_status
        fi

        shift
        relx_rem_sh
        ;;

    upgrade|downgrade|install)
        if [ -z "$2" ]; then
            echo "Missing package argument"
            echo "Usage: $REL_NAME $1 {package base name}"
            echo "NOTE {package base name} MUST NOT include the .tar.gz suffix"
            exit 1
        fi

        # Make sure a node IS running
        relx_nodetool "ping" > /dev/null
        exit_status=$?
        if [ "$exit_status" -ne 0 ]; then
            echo "Node is not running!"
            exit $exit_status
        fi

        # We have to unpack the release first in order to make sure the configuration
        # is properly updated. This also destroys the .tar.gz package (release_handler does)
        "$BINDIR/escript" "$ROOTDIR/bin/install_upgrade.escript" \
             "unpack" "$REL_NAME" "$NAME_TYPE" "$NAME" "$COOKIE" "$2"

        echo "Generating vm.args/sys.config for upgrade..."
        __release_conf="$RELEASES_DIR/$2/$REL_NAME.conf"
        __release_schema="$RELEASES_DIR/$2/$REL_NAME.schema.exs"
        __release_config="$RELEASES_DIR/$2/sys.config"
        __release_args="$RELEASES_DIR/$2/vm.args"
        __running_conf="$GENERATED_CONFIG_DIR/$REL_NAME.conf"
        __running_config="$GENERATED_CONFIG_DIR/sys.config"
        __running_args="$GENERATED_CONFIG_DIR/vm.args"
        # Make sure the .conf is copied to the running-config directory
        if [ -f "$__release_conf" ]; then
            # Preserve previous conf for reference
            if [ -f "$__running_conf" ]; then
                cp "$__running_conf" "$__running_conf.last"
            fi
            cp "$__release_conf" "$__running_conf"
        fi
        __conform="$RELEASES_DIR/$2/conform"
        # Handle the case where the target version did not bundle conform in the release
        if [ ! -f "$__conform" ]; then
            __conform="$ROOTDIR/bin/conform"
        fi
        # Generate the sys.config for the release
        # If a .conf is not provided, then preserve the last sys.config for reference, and copy the new sys.config
        # to running-config.
        if [ -f "$__running_conf" ]; then
            if [ -f "$__release_schema" ]; then
                result="$("$BINDIR/escript" "$__conform" --conf "$__running_conf" --schema "$__release_schema" --config "$__release_config" --output-dir "$RELEASES_DIR/$2")"
                exit_status="$?"
                if [ "$exit_status" -ne 0 ]; then
                    echo "Could not generate the sys.config for the new release. Please review the following files:"
                    echo "$REL_NAME.conf: $__running_conf"
                    echo "$REL_NAME.schema.exs: $__release_schema"
                    echo "sys.config: $__release_config"
                    exit "$exit_status"
                else
                  cp "$__release_config" "$__running_config"
                fi
            fi
        else
            if [ -f "$__running_config" ]; then
                cp "$__running_config" "$__running_config.last"
                cp "$__release_config" "$__running_config"
            fi
        fi
        echo "sys.config ready!"
        if [ -f "$__running_args" ]; then
          cp "$__release_args" "$__release_args.orig"
          cp "$__running_args" "$__release_args"
        else
          cp "$__release_args" "$__running_args"
        fi
        echo "vm.args ready!"

        exec "$BINDIR/escript" "$ROOTDIR/bin/install_upgrade.escript" \
             "install" "$REL_NAME" "$NAME_TYPE" "$NAME" "$COOKIE" "$2"
        ;;

    unpack)
        if [ -z "$2" ]; then
            echo "Missing package argument"
            echo "Usage: $REL_NAME $1 {package base name}"
            echo "NOTE {package base name} MUST NOT include the .tar.gz suffix"
            exit 1
        fi

        # Make sure a node IS running
        if ! relx_nodetool "ping" > /dev/null; then
            echo "Node is not running!"
            exit 1
        fi

        exec "$BINDIR/escript" "$ROOTDIR/bin/install_upgrade.escript" \
             "unpack" "$REL_NAME" "$NAME_TYPE" "$NAME" "$COOKIE" "$2"
        ;;

    console|console_clean|console_boot)
        # Make sure the config is generated first
        generate_config
        # .boot file typically just $REL_NAME (ie, the app name)
        # however, for debugging, sometimes start_clean.boot is useful.
        # For e.g. 'setup', one may even want to name another boot script.
        __console_flags=""
        case "$1" in
            console)
                __console_flags="-mode embedded"
                if [ -f "$REL_DIR/$REL_NAME.boot" ]; then
                    BOOTFILE="$REL_DIR/$REL_NAME"
                else
                    BOOTFILE="$REL_DIR/start"
                fi
                ;;
            console_clean)
                BOOTFILE="$ROOTDIR/bin/start_clean"
                ;;
            console_boot)
                shift
                BOOTFILE="$1"
                shift
                ;;
        esac
        # Setup beam-required vars
        EMU="beam"
        PROGNAME="${0#*/}"

        export EMU
        export PROGNAME

        # Store passed arguments since they will be erased by `set`
        ARGS="$@"

        # Build an array of arguments to pass to exec later on
        # Build it here because this command will be used for logging.
        set -- "$BINDIR/erlexec" \
            -boot "$BOOTFILE" -config "$SYS_CONFIG" \
            -boot_var ERTS_LIB_DIR "$ERTS_LIB_DIR" \
            -env ERL_LIBS "$REL_LIB_DIR" \
            -pa "$CONSOLIDATED_DIR" \
            -args_file "$VMARGS_PATH" \
            ${__console_flags} \
            ${ERL_OPTS} \
            ${CONFORM_OPTS} \
            -user Elixir.IEx.CLI -extra --no-halt +iex

        # Dump environment info for logging purposes
        echo "Exec: $@" -- ${1+$ARGS}
        echo "Root: $ROOTDIR"

        # Log the startup
        echo "$RELEASE_ROOT_DIR"
        logger -t "$REL_NAME[$$]" "Starting up"

        # Start the VM
        exec "$@" -- ${1+$ARGS}
        ;;

    foreground)
        # Make sure the config is generated first
        generate_config
        # start up the release in the foreground for use by runit
        # or other supervision services

        [ -f "$REL_DIR/$REL_NAME.boot" ] && BOOTFILE="$REL_NAME" || BOOTFILE="start"
        FOREGROUNDOPTIONS="-noshell -noinput +Bd"

        # Setup beam-required vars
        EMU="beam"
        PROGNAME="${0#*/}"

        export EMU
        export PROGNAME

        # Store passed arguments since they will be erased by `set`
        ARGS="$@"

        # Build an array of arguments to pass to exec later on
        # Build it here because this command will be used for logging.
        set -- "$BINDIR/erlexec" $FOREGROUNDOPTIONS \
            -boot "$REL_DIR/$BOOTFILE" -mode embedded -config "$SYS_CONFIG" \
            -boot_var ERTS_LIB_DIR "$ERTS_LIB_DIR" \
            -env ERL_LIBS "$REL_LIB_DIR" \
            -pa "$CONSOLIDATED_DIR" \
            ${ERL_OPTS} \
            ${CONFORM_OPTS} \
            -args_file "$VMARGS_PATH"

        # Dump environment info for logging purposes
        echo "Exec: $@" -- ${1+$ARGS}
        echo "Root: $ROOTDIR"

        # Start the VM
        exec "$@" -- ${1+$ARGS}
        ;;

    command)
        # Make sure the config is generated first
        generate_config

        # Execute as command-line utility
        #
        # Like the escript command, this does not start the OTP application.
        # If your command depends on a running OTP application,
        # use
        #
        #     {:ok, _} = Application.ensure_all_started(:your_app)

        shift
        MODULE="$1"; shift
        FUNCTION="$1"; shift

        # Save extra arguments
        ARGS="$@"

        # Build arguments for erlexec
        set -- "$ERL_OPTS"
        [ "$SYS_CONFIG" ] && set -- "$@" -config "$SYS_CONFIG"
        set -- "$@" -boot_var ERTS_LIB_DIR "$ERTS_LIB_DIR"
        set -- "$@" -noshell
        set -- "$@" -boot $REL_DIR/start_clean
        set -- "$@" -s "$MODULE" "$FUNCTION"

        # Boot the release
        $BINDIR/erlexec $@ -extra $ARGS
        exit "$?"
        ;;

    *)
        echo "Usage: $REL_NAME {start|start_boot <file>|foreground|stop|restart|reboot|ping|rpc <m> <f> [<a>]|console|console_clean|console_boot <file>|attach|remote_console|upgrade|escript|command <m> <f> <args>}"
        exit 1
        ;;
esac

exit 0
