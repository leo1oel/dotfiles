# >>> hyak cuda setup >>>
# Initialize Hyak Lmod for interactive fish shells.
if status is-interactive
    if test (uname) = Linux
        if not functions -q module
            if test -f /opt/ohpc/admin/lmod/lmod/init/fish
                source /opt/ohpc/admin/lmod/lmod/init/fish
            end
        end

        # Auto-load compiler + CUDA toolkit on compute nodes only.
        if functions -q module
            set -l __hn (hostname)
            if string match -rq '^g[0-9]+$' -- $__hn
                # Load the newest available GCC; CUDA needs a newer host compiler.
                set -l __gcc_ver (module avail gcc 2>&1 | string match -rga 'gcc/([0-9.]+)' | sort -t/ -k2 -V | tail -1)
                if test -n "$__gcc_ver"
                    module load $__gcc_ver 2>/dev/null
                end

                # After GCC is loaded, pick the newest CUDA that becomes available.
                set -l __cuda_ver (module avail cuda 2>&1 | string match -rga 'cuda/([0-9.]+)' | sort -t/ -k2 -V | tail -1)
                if test -n "$__cuda_ver"
                    module load $__cuda_ver 2>/dev/null
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
