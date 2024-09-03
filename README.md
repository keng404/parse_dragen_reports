# parse_dragen_reports
A simple parser to grab content from tables in [DRAGEN Reports](https://help.dragen.illumina.com/product-guides/dragen-v4.3/dragen-reports) HTML files
and generate text files with this information for downstream reporting and visualization

```bash
Rscript parse_dragen_reports.R --html {html_file}
```

## For convenience you can use the docker image
## keng404/parse_dragen_reports:0.0.3