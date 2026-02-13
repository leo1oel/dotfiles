# >>> hyak cuda setup >>>
# Initialize Hyak Lmod for interactive fish shells.
if status is-interactive
    if test (uname) = Linux
        if not functions -q module
            if test -f /usr/share/lmod/lmod/init/fish
                source /usr/share/lmod/lmod/init/fish
            else if test -f /opt/ohpc/admin/lmod/lmod/init/fish
                source /opt/ohpc/admin/lmod/lmod/init/fish
            end
        end

        # Define cuda-init command to manually load GCC + CUDA on compute nodes.
        if functions -q module
            function cuda-init -d "Load the newest GCC and CUDA modules"
                # Load the newest available GCC; CUDA needs a newer host compiler.
                set -l __gcc_ver (module avail gcc 2>&1 | string match -ra 'gcc/[0-9.]+' | sort -t/ -k2 -V | tail -1)
                if test -n "$__gcc_ver"
                    module load $__gcc_ver 2>/dev/null
                    echo "Loaded $__gcc_ver"
                end

                # After GCC is loaded, pick the newest CUDA that becomes available.
                set -l __cuda_ver (module avail cuda 2>&1 | string match -ra 'cuda/[0-9.]+' | sort -t/ -k2 -V | tail -1)
                if test -n "$__cuda_ver"
                    module load $__cuda_ver 2>/dev/null
                    echo "Loaded $__cuda_ver"
                end

                if command -q gcc
                    set -gx CC (command -s gcc)
                end
                if command -q g++
                    set -gx CXX (command -s g++)
                    set -gx CUDAHOSTCXX (command -s g++)
                end

                if command -q nvcc
                    set -gx CUDA_HOME (dirname (dirname (command -s nvcc)))
                    if not contains -- $CUDA_HOME/bin $PATH
                        set -gx PATH $CUDA_HOME/bin $PATH
                    end
                    if set -q LD_LIBRARY_PATH
                        if not contains -- $CUDA_HOME/lib64 $LD_LIBRARY_PATH
                            set -gx LD_LIBRARY_PATH $CUDA_HOME/lib64 $LD_LIBRARY_PATH
                        end
                    else
                        set -gx LD_LIBRARY_PATH $CUDA_HOME/lib64
                    end
                end
            end
        end
    end
end
# <<< hyak cuda setup <<<
