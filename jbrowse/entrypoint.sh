#!/bin/sh
set -e

JBROWSE_DIR="/usr/share/nginx/html"
DATA_URL="http://localhost/data"
FOUND_ASSEMBLY=0

# Configure hg38 assembly if reference genome is present
if [ -f /data/hg38/hg38.fa ] && [ -f /data/hg38/hg38.fa.fai ]; then
    echo "Configuring hg38 (GRCh38) assembly..."
    jbrowse add-assembly "${DATA_URL}/hg38/hg38.fa" \
        --name "hg38" \
        --displayName "Human (GRCh38/hg38)" \
        --type indexedFasta \
        --out "$JBROWSE_DIR" \
        --load inPlace \
        --overwrite 2>/dev/null || true
    FOUND_ASSEMBLY=1
fi

# Configure hg19 assembly if reference genome is present
if [ -f /data/hg19/hg19.fa ] && [ -f /data/hg19/hg19.fa.fai ]; then
    echo "Configuring hg19 (GRCh37) assembly..."
    jbrowse add-assembly "${DATA_URL}/hg19/hg19.fa" \
        --name "hg19" \
        --displayName "Human (GRCh37/hg19)" \
        --type indexedFasta \
        --out "$JBROWSE_DIR" \
        --load inPlace \
        --overwrite 2>/dev/null || true
    FOUND_ASSEMBLY=1
fi

if [ "$FOUND_ASSEMBLY" -eq 0 ]; then
    echo ""
    echo "=========================================="
    echo "  No reference genome found in /data/"
    echo "=========================================="
    echo ""
    echo "To use JBrowse, place reference genome files in the data directory:"
    echo ""
    echo "  For hg38 (GRCh38):"
    echo "    mkdir -p data/hg38"
    echo "    wget -P data/hg38 https://hgdownload.soe.ucsc.edu/goldenPath/hg38/bigZips/hg38.fa.gz"
    echo "    gunzip data/hg38/hg38.fa.gz"
    echo "    samtools faidx data/hg38/hg38.fa"
    echo ""
    echo "  For hg19 (GRCh37):"
    echo "    mkdir -p data/hg19"
    echo "    wget -P data/hg19 https://hgdownload.soe.ucsc.edu/goldenPath/hg19/bigZips/hg19.fa.gz"
    echo "    gunzip data/hg19/hg19.fa.gz"
    echo "    samtools faidx data/hg19/hg19.fa"
    echo ""
    echo "Then restart: docker compose restart jbrowse"
    echo ""
    echo "JBrowse will still start -- you can also open files"
    echo "via the UI using Open > Track > URL."
    echo "=========================================="
    echo ""
fi

# Auto-add any VCF tracks found in /data/
for vcf in /data/*.vcf.gz; do
    [ -f "$vcf" ] || continue
    tbi="${vcf}.tbi"
    csi="${vcf}.csi"
    if [ -f "$tbi" ] || [ -f "$csi" ]; then
        trackname=$(basename "$vcf" .vcf.gz)
        echo "Adding VCF track: ${trackname}"
        # Try to add against each available assembly
        for assembly in hg38 hg19; do
            if [ -f "/data/${assembly}/${assembly}.fa" ]; then
                jbrowse add-track "${DATA_URL}/$(basename "$vcf")" \
                    --name "$trackname" \
                    --trackId "${trackname}_${assembly}" \
                    --assemblyNames "$assembly" \
                    --out "$JBROWSE_DIR" \
                    --load inPlace \
                    --overwrite 2>/dev/null || true
            fi
        done
    else
        echo "Skipping $(basename "$vcf") -- no .tbi or .csi index found"
    fi
done

echo "Starting JBrowse 2 at http://localhost:3000"
exec nginx -g "daemon off;"
