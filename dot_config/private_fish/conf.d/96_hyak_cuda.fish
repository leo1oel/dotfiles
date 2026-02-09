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
                # Load GCC first; CUDA extension builds often need a newer host compiler.
                module load gcc/11.2.0 2>/dev/null
                module load cuda/12.4.1 2>/dev/null

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
