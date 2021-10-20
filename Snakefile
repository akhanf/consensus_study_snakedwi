configfile: 'config.yml'

rule all_submit:
    input:
        dwi = expand('submit/{subject}/preproc/dwi.{ext}',
                subject=config['subjects'],
                ext=['nii.gz','bval','bvec'])
       
rule all_snakedwi:
    input:
        outdir = expand('snakedwi_nslices-{nslices}.cmd',
                            nslices=config['nslices'])


rule dwi_ap:
    input: config['dwi_ap']
    output: 'bids/sub-{subject}/dwi/sub-{subject}_acq-AP_dwi.{ext,nii.gz|bval|bvec}'
    shell: 'cp {input} {output}'

rule dwi_ap_json:
    """ force PhaseEncodingDirection to be j """
    input: 
        json = config['dwi_ap']
    output: 
        json = 'bids/sub-{subject}/dwi/sub-{subject}_acq-AP_dwi.{ext,json}'
    run: 
        import json
        with open(input.json) as f:
            json_dict = json.load(f)
        json_dict['PhaseEncodingDirection'] = 'j'
        with open(output.json, 'w') as f:
            json.dump(json_dict, f,indent=4)


rule dwi_pa:
    input: config['dwi_pa']
    output: 'bids/sub-{subject}/dwi/sub-{subject}_acq-PA_dwi.{ext,nii.gz}'
    shell: 'cp {input} {output}'

rule dwi_pa_json:
    """ force PhaseEncodingDirection to be j- """
    input: 
        json = config['dwi_pa']
    output: 
        json = 'bids/sub-{subject}/dwi/sub-{subject}_acq-PA_dwi.{ext,json}'
    run: 
        import json
        with open(input.json) as f:
            json_dict = json.load(f)
        json_dict['PhaseEncodingDirection'] = 'j-'
        with open(output.json, 'w') as f:
            json.dump(json_dict, f,indent=4)



    


rule dwi_pa_bval:
    output: 'bids/sub-{subject}/dwi/sub-{subject}_acq-PA_dwi.bval'
    shell: 'echo 0 > {output}'

rule dwi_pa_bvec:
    output: 'bids/sub-{subject}/dwi/sub-{subject}_acq-PA_dwi.bvec'
    shell: "echo '0\n0\n0' > {output}"

rule anat:
    input: config['t1w']
    output: 'bids/sub-{subject}/anat/sub-{subject}_T1w.{ext}'
    shell: 'cp {input} {output}'




rule get_lists:
    input: expand('bids/sub-{subject}/dwi/sub-{subject}_acq-AP_dwi.nii.gz', subject=config['subjects'])
    params:
        subjects = config['subjects']
    output: 'resources/subjects_nslices-{nslices}.txt'
    shell: 
        'for subj in {params.subjects};'
        'do '
        ' nslices=`fslval bids/sub-${{subj}}/dwi/sub-${{subj}}_acq-AP_dwi.nii.gz dim3` && ' 
        ' if [ ${{nslices}} == {wildcards.nslices} ];' 
        ' then ' 
        '   echo ${{subj}} >> {output};' 
        ' fi; ' 
        'done'


rule dataset_description:
    input:
        t1 = expand('bids/sub-{subject}/anat/sub-{subject}_T1w.{ext}',
                subject=config['subjects'],
                ext=['json','nii.gz']),
        dwi = expand('bids/sub-{subject}/dwi/sub-{subject}_acq-{acq}_dwi.{ext}',
                subject=config['subjects'],
                acq=['AP','PA'],
                ext=['json','nii.gz','bval','bvec']),
        dd = 'resources/dataset_description.json',
    output: 
        dd = 'bids/dataset_description.json'
    shell: 'cp {input.dd} {output.dd}'
        
rule run_snakedwi:
    input: 
        dd = 'bids/dataset_description.json',
        custom = 'resources/custom_slspec_{nslices}slices.txt',
        subjects = 'resources/subjects_nslices-{nslices}.txt'
    params:
        bids_dir = 'bids',
        out_dir = 'snakedwi_nslices-{nslices}'
    output: 
        cmd = 'snakedwi_nslices-{nslices}.cmd'
    shell: 'echo snakedwi {params.bids_dir} {params.out_dir} participant --profile cc-slurm --no_bedpost --participant_label `cat {input.subjects}` --slspec_txt {input.custom} > {output.cmd}'





rule cp_submit_folder:
    input:
        in_folders = expand('snakedwi_nslices-{nslices}',nslices=config['nslices']),
    output:
        submit_folder = directory('submit_norename'),
        dwi = expand('submit_norename/sub-{subject}_desc-eddy_dwi.{ext}',
                subject=config['subjects'],
                ext=['nii.gz','bval','bvec'])
    shell:
        'for folder in {input}; do cp -v ${{folder}}/results/sub-*/dwi/sub-?????_desc-eddy_dwi.* {output.submit_folder}; done'
 
rule rename_submit:
    input:
        dwi = 'submit_norename/sub-{subject}_desc-eddy_dwi.{ext}',
    output:
        dwi = 'submit/{subject}/preproc/dwi.{ext}'
    shell: 'cp -v {input} {output}'

       
