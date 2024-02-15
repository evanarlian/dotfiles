function ca --description "conda activate and deactivate"
    if test -z "$argv"
        conda deactivate
    else
        conda activate $argv
    end
    return $status
end
