function mkdir_no_warn(dirname)
    if ~exist(dirname, 'dir')
        mkdir(dirname)
    end
end