
# wrapper functions of ccg2lambda/scripts/
from subprocess import run
from pathlib import Path
import logging
from lxml import etree

from scripts.semantic_index import SemanticIndex
from scripts.semparse import semantic_parse_sentence
from scripts.semantic_types import get_dynamic_library_from_doc

from scripts.theorem import make_coq_script, prove_script


def _jiggparse(inputname, outname):
    assert inputname.exists()
    assert not inputname.is_dir()
    assert not outname.is_dir()
    jigg_dir = "ja/jigg-v-0.4/jar/*"
    jigg = run(["java", "-Xmx4g", "-cp", jigg_dir, "jigg.pipeline.Pipeline",
                "-annotators", "ssplit,kuromoji,ccg", "-ccg.kBest", "10",
                "-file", str(inputname),
                "-output", str(outname)], capture_output=True)
    stdout = jigg.stdout.decode()
    stderr = jigg.stderr.decode()
    # print("stdout:", stdout)
    # print("stderr first 50 characters: ", [:50])
    if not outname.exists():
        raise Exception("output file doesn't exist,"
                        "so jigg seems to have failed.")
    return


def _semparse(inputname):
    assert inputname.exists()
    semantic_template = "ja/semantic_templates_ja_emnlp2016.yaml"
    logging.basicConfig(level=logging.WARNING)

    semantic_index = SemanticIndex(semantic_template)

    parser = etree.XMLParser(remove_blank_text=True)
    root = etree.parse(str(inputname), parser)

    sentences = root.findall('.//sentence')
    assert len(sentences) == 1
    # print('Found {0} sentences'.format(len(sentences)))
    # from pudb import set_trace; set_trace()
    sentence = sentences[0]
    sem_nodes_str_list = semantic_parse_sentence(sentence, semantic_index)
    sem_nodes = [etree.fromstring(s) for s in sem_nodes_str_list]
    logging.info('Adding XML semantic nodes to sentences...')
    sentence.extend(sem_nodes)
    logging.info('Finished adding XML semantic nodes to sentences.')
    # extract logic expressions
    doc = root.xpath('./document')[0]
    _semantics = doc.xpath('./sentences/sentence/semantics')
    semantics = [sem for sem in _semantics
                 if sem.get('status', 'failed') == 'success']
    dynamic_library_str, formulas = get_dynamic_library_from_doc(doc,
                                                                 semantics)
    formulas_str = [str(f) for f in formulas]
    return dynamic_library_str, formulas_str


def j2l(japanese_input):
    # prepare text file which contains japanese_input
    tmpdir = Path('/tmp/ccg2lambda')
    tmpdir.mkdir(exist_ok=True)
    tmptxt = tmpdir / 'tmp.txt'
    tmpccg = tmpdir / 'tmpccg.xml'
    tmptxt.write_text(japanese_input)

    # convert tmp.txt to formulas&Parameters
    _jiggparse(tmptxt, tmpccg)
    dynamic_library_str, formulas_str = _semparse(tmpccg)
    return dynamic_library_str, formulas_str


def _prove(premises, conclusion, dynamic_library_str):
    coq_script = make_coq_script(premises, conclusion,
                                 dynamic_library_str)
    inf_result_bool = prove_script(coq_script, timeout=100)
    return inf_result_bool


if __name__ == '__main__':
    japanese_input = 'すべての人間は死ぬ。'
    dls, fml = j2l(japanese_input)
    inf_result_bool = _prove([fml[0]], fml[-1], dls)
