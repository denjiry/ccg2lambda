
# wrapper functions of ccg2lambda/scripts/
from subprocess import run
from pathlib import Path
import codecs
import logging
from lxml import etree

from scripts.semantic_index import SemanticIndex
from scripts.semparse import (semantic_parse_sentences,
                              serialize_tree)

from scripts.theorem import make_coq_script


def _jiggparse(txtfilename):
    assert Path(txtfilename).exists()
    jigg_dir = "ja/jigg-v-0.4/jar/*"
    jigg = run(["java", "-Xmx4g", "-cp", jigg_dir, "jigg.pipeline.Pipeline",
                "-annotators", "ssplit,kuromoji,ccg", "-ccg.kBest", "10",
                "-file", txtfilename], capture_output=True)
    stdout = jigg.stdout.decode()
    stderr = jigg.stderr.decode()
    # print("stdout:", stdout)
    # print("stderr first 50 characters: ", [:50])
    if not Path(txtfilename+".xml").exists():
        raise Exception("output file doesn't exist,"
                        "so jigg seems to have failed.")
    return


def _semparse(txtfilename):
    assert Path(txtfilename).exists()
    ccg_tree = txtfilename+".xml"
    semantic_template = "ja/semantic_templates_ja_emnlp2016.yaml"
    out = txtfilename+".sem.xml"

    logging.basicConfig(level=logging.WARNING)

    semantic_index = SemanticIndex(semantic_template)

    parser = etree.XMLParser(remove_blank_text=True)
    root = etree.parse(ccg_tree, parser)

    sentences = root.findall('.//sentence')
    # print('Found {0} sentences'.format(len(sentences)))
    # from pudb import set_trace; set_trace()
    sentence_inds = range(len(sentences))
    sem_nodes_lists = semantic_parse_sentences(sentence_inds,
                                               sentences, semantic_index)
    assert len(sem_nodes_lists) == len(sentences), \
        'Element mismatch: {0} vs {1}'.format(len(sem_nodes_lists), len(sentences))
    logging.info('Adding XML semantic nodes to sentences...')
    for sentence, sem_nodes in zip(sentences, sem_nodes_lists):
        sentence.extend(sem_nodes)
    logging.info('Finished adding XML semantic nodes to sentences.')

    root_xml_str = serialize_tree(root)
    with codecs.open(out, 'wb') as fout:
        fout.write(root_xml_str)
    return


def _visualize(txtfilename):
    assert Path(txtfilename).exists()
    cp = run(["python", "scripts/visualize.py",
              txtfilename+".sem.xml"],
             capture_output=True)
    stdout = cp.stdout.decode()
    stderr = cp.stderr.decode()
    # print("stdout:", stdout)
    # print("stderr first 50 characters: ", [:50])
    with Path(txtfilename+".html").open('w') as f:
        f.write(stdout)
    return


def _prove(txtfilename):
    assert Path(txtfilename).exists(), txtfilename+" does not exists."
    cp = run(["python", "scripts/prove.py",
              txtfilename+".sem.xml",
              "--graph_out", txtfilename+".prove.html"],
             capture_output=True)
    stdout = cp.stdout.decode()
    stderr = cp.stderr.decode()
    # print("stdout:", stdout)
    # print("stderr first 50 characters: ", [:50])
    assert stdout.rstrip("\n") in ["yes", "no", "unknown"]
    return


if __name__ == '__main__':
    filename = 'tmp.txt'
    _jiggparse(filename)
    _semparse(filename)
    # _visualize(filename)
    # _prove('pr'+filename)
