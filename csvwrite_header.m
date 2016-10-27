function csvwrite_header(filename, M, header)
    fid = fopen(filename, 'w');
    if nargin > 2
      fprintf(fid, [header, '\n']);
    end
    fclose(fid);
    dlmwrite(filename, M, '-append', 'precision', '%e', 'delimiter', ',');

end
