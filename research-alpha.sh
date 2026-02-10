#!/bin/bash
# Research Alpha - Scientific Breakthroughs Scanner
# Uses PubMed API for free paper access

set -e

WORKSPACE="/root/.openclaw/workspace/dash3/docs"
OUTPUT="$WORKSPACE/resulted.md"
TEMP_FILE="/tmp/research_alpha_temp.md"

DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
DATE_DISPLAY=$(date +"%Y-%m-%d")

cat > "$TEMP_FILE" << EOF
# Research Alpha - Scientific Breakthroughs

_Last updated: ${DATE}_

---

EOF

# Function to process papers
process_papers() {
    local ids="$1"
    local sector="$2"
    
    [ -z "$ids" ] && return
    
    # Fetch XML
    local xml=$(curl -s "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=pubmed&id=${ids}&retmode=xml" 2>/dev/null)
    
    # Use python for parsing (more reliable)
    python3 << PYEOF
import xml.etree.ElementTree as ET
import re
import sys

xml = '''$xml'''
sector = '$sector'
date_display = '$DATE_DISPLAY'

try:
    root = ET.fromstring(xml)
    
    for article in root.findall('.//PubmedArticle'):
        try:
            # Title
            title_elem = article.find('.//ArticleTitle')
            title = title_elem.text if title_elem is not None and title_elem.text else ''
            
            # Abstract
            abstract_texts = article.findall('.//AbstractText')
            abstract = ' '.join([t.text or '' for t in abstract_texts if t.text])[:500]
            
            # PMID
            pmid_elem = article.find('.//PMID')
            pmid = pmid_elem.text if pmid_elem is not None else ''
            
            if not title or not pmid:
                continue
            
            # Skip US/Saudi
            combined = (title + ' ' + abstract).lower()
            if any(x in combined for x in ['united states', 'american', 'usa', 'saudi', 'ksa']):
                continue
            
            # Region
            region = 'International'
            if any(x in abstract.lower() for x in ['china', 'chinese', 'beijing']):
                region = 'China'
            elif any(x in abstract.lower() for x in ['japan', 'tokyo']):
                region = 'Japan'
            elif any(x in abstract.lower() for x in ['korea', 'seoul']):
                region = 'South Korea'
            elif any(x in abstract.lower() for x in ['germany', 'german']):
                region = 'Germany'
            elif any(x in abstract.lower() for x in ['uk', 'britain', 'london']):
                region = 'UK'
            elif any(x in abstract.lower() for x in ['france', 'french']):
                region = 'France'
            elif 'israel' in abstract.lower():
                region = 'Israel'
            
            # Timeline
            timeline = '2-5 years'
            if any(x in abstract.lower() for x in ['clinical trial', 'phase iii', 'commercial', 'market launch']):
                timeline = '<6 months'
            elif any(x in abstract.lower() for x in ['phase ii', 'prototype', 'pilot']):
                timeline = '<1 year'
            elif any(x in abstract.lower() for x in ['phase i', 'proof of concept']):
                timeline = '1-3 years'
            
            # Confidence
            confidence = 50
            if any(x in abstract.lower() for x in ['patent', 'commercial', 'market', 'company']):
                confidence += 15
            if any(x in abstract.lower() for x in ['clinical', 'phase']):
                confidence += 10
            if any(x in abstract.lower() for x in ['breakthrough', 'record', 'novel']):
                confidence += 10
            confidence = min(confidence, 95)
            
            # Insight
            insight = 'Research with investment potential'
            if sector == 'Biotech':
                if 'cancer' in abstract.lower() or 'tumor' in abstract.lower():
                    insight = 'Oncology - watch for pharma partnerships'
                elif 'vaccine' in abstract.lower():
                    insight = 'Vaccine innovation - pandemic plays'
                elif 'gene' in abstract.lower() or 'crispr' in abstract.lower():
                    insight = 'Gene therapy - biotech sector'
            elif sector == 'Energy':
                if 'battery' in abstract.lower() or 'storage' in abstract.lower():
                    insight = 'Battery tech - EV & grid storage'
                elif 'solar' in abstract.lower():
                    insight = 'Solar advance - renewable sector'
                elif 'hydrogen' in abstract.lower():
                    insight = 'Hydrogen - clean energy transition'
            elif sector == 'Semiconductor':
                if 'quantum' in abstract.lower():
                    insight = 'Quantum computing - early stage'
                elif 'ai chip' in abstract.lower() or 'neural' in abstract.lower():
                    insight = 'AI chip - hardware growth'
            elif sector == 'Materials':
                insight = 'Advanced materials - multi-sector applications'
            
            # Output
            print(f'''
## {title}

**Sector:** {sector}
**Region:** {region}
**Timeline:** {timeline}
**Confidence:** {confidence}
**Insight:** {insight}
**Link:** [PubMed](https://pubmed.ncbi.nlm.nih.gov/{pmid}/)
**Date:** {date_display}

---

''')
        except Exception as e:
            continue
            
except Exception as e:
    pass
PYEOF
}

echo "🔬 Biotech..."
echo "" >> "$TEMP_FILE"
echo "## 🧬 Biotech Breakthroughs" >> "$TEMP_FILE"
ids=$(curl -s "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi?db=pubmed&term=drug+therapy+clinical+trial+breakthrough+2025&retmax=5&retmode=json" | jq -r '.esearchresult.idlist[]?' | tr '\n' ',' | sed 's/,$//')
process_papers "$ids" "Biotech" >> "$TEMP_FILE"

echo "⚡ Energy..."
echo "" >> "$TEMP_FILE"
echo "## ⚡ Energy Breakthroughs" >> "$TEMP_FILE"
ids=$(curl -s "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi?db=pubmed&term=battery+energy+storage+solar+hydrogen+2025&retmax=5&retmode=json" | jq -r '.esearchresult.idlist[]?' | tr '\n' ',' | sed 's/,$//')
process_papers "$ids" "Energy" >> "$TEMP_FILE"

echo "💻 Chips..."
echo "" >> "$TEMP_FILE"
echo "## 💻 Semiconductor Breakthroughs" >> "$TEMP_FILE"
ids=$(curl -s "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi?db=pubmed&term=semiconductor+quantum+computing+chip+2025&retmax=5&retmode=json" | jq -r '.esearchresult.idlist[]?' | tr '\n' ',' | sed 's/,$//')
process_papers "$ids" "Semiconductor" >> "$TEMP_FILE"

echo "🔬 Materials..."
echo "" >> "$TEMP_FILE"
echo "## 🔬 Materials Breakthroughs" >> "$TEMP_FILE"
ids=$(curl -s "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi?db=pubmed&term=nanomaterial+graphene+new+material+2025&retmax=5&retmode=json" | jq -r '.esearchresult.idlist[]?' | tr '\n' ',' | sed 's/,$//')
process_papers "$ids" "Materials" >> "$TEMP_FILE"

mv "$TEMP_FILE" "$OUTPUT"
echo "✅ Done: $(date)"
