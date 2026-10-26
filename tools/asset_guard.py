"""Keep finished custom graphics when a legacy placeholder drawing script is run."""
from pathlib import Path
import json
import os

ART=Path(__file__).resolve().parents[1]/'art'

def save_asset(image,path):
    target=Path(path)
    registry=ART/'.codex_assets.json'
    if target.exists() and registry.exists() and os.environ.get('CHEAP_ALLOW_PLACEHOLDERS')!='1':
        try:
            relative=target.resolve().relative_to(ART.resolve()).as_posix()
            protected=json.loads(registry.read_text(encoding='utf-8')).get('files',[])
            if relative in protected:
                print('Grafica definitiva conservata: art/'+relative)
                return False
        except (ValueError,OSError):
            pass
    image.save(target)
    return True
