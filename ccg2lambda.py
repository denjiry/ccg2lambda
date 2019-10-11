
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


def _jiggparse(inputname, outname):
    assert Path(inputname).exists()
    assert not Path(inputname).is_dir()
    assert not Path(outname).is_dir()
    jigg_dir = "ja/jigg-v-0.4/jar/*"
    jigg = run(["java", "-Xmx4g", "-cp", jigg_dir, "jigg.pipeline.Pipeline",
                "-annotators", "ssplit,kuromoji,ccg", "-ccg.kBest", "10",
                "-file", inputname,
                "-output", outname], capture_output=True)
    stdout = jigg.stdout.decode()
    stderr = jigg.stderr.decode()
    # print("stdout:", stdout)
    # print("stderr first 50 characters: ", [:50])
    if not Path(outname).exists():
        raise Exception("output file doesn't exist,"
                        "so jigg seems to have failed.")
    return


def _semparse(inputname, outname):
    assert Path(inputname).exists()
    semantic_template = "ja/semantic_templates_ja_emnlp2016.yaml"
    logging.basicConfig(level=logging.WARNING)

    semantic_index = SemanticIndex(semantic_template)

    parser = etree.XMLParser(remove_blank_text=True)
    root = etree.parse(inputname, parser)

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
    with codecs.open(outname, 'wb') as fout:
        fout.write(root_xml_str)
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
    txtname = 'tmp.txt'
    tmpccg = '/tmp/tmpccg.xml'
    tmpsem = '/tmp/tmpsem.xml'
    _jiggparse(txtname, tmpccg)
    _semparse(tmpccg, tmpsem)
    # _prove('pr'+filename)
