// Nextflow pipeline for book text analysis

// Paths
params.output_path = "$projectDir/results_nf/"
params.data_path = "$projectDir/data/"
params.code_path = "$projectDir/code/"

process remove_pg {
    publishDir "$params.output_path/remove_pg/"

    input:
    tuple path(input_path), val(genre), val(title)
    
    output:
    tuple path("$genre/${title}_clean.txt"), val(genre), val(title)
    
    script:
    """
    python $params.code_path/remove_pg.py $input_path $genre/${title}_clean.txt
    """
}

process count_words {
    publishDir "$params.output_path/count_words/"

    input:
    tuple path(input_path), val(genre), val(title)

    output:
    tuple path("$genre/${title}_counts.tsv"), val(genre), val(title)
    
    script:
    """
    python $params.code_path/count_words.py $input_path $genre/${title}_counts.tsv
    """
}

process basic_stats {
    publishDir "$params.output_path/basic_stats/"

    input:
    tuple path(input_path), val(genre), val(title)

    output:
    tuple path("$genre/${title}_stats.txt"), val(genre), val(title)

    script:
    """
    python $params.code_path/basic_stats.py $input_path $genre/${title}_stats.txt
    """
}

process transpose_stats {
    publishDir "$params.output_path/aggregate_stats/"

    input:
    tuple path(input_path), val(genre), val(title)

    output:
    stdout

    shell:
    '''
    text=$(awk 'BEGIN {FS=": "; OFS="\t"}{print $1,$2}' !{input_path})
    printf "%s\t%s\t" genre title
    echo "$text" | cut -f 1 | paste -s -
    printf "%s\t%s\t" !{genre} !{title}
    echo "$text" | cut -f 2 | paste -s -
    '''
}

workflow {
    file_paths = channel.fromPath("$params.data_path/*/*.txt")
    file_records = file_paths.map({[it, it.parent.baseName, it.baseName]})
    clean_records = remove_pg(file_records)
    count_records = count_words(clean_records)
    basic_stats = basic_stats(count_records)
    aggregated = transpose_stats(basic_stats).collectFile(name: 'aggregated.tsv', storeDir: projectDir, keepHeader: true, skip: 1)
}
