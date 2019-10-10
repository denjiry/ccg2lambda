#!/usr/bin/python3
# -*- coding: utf-8 -*-
#
#  Copyright 2015 Pascual Martinez-Gomez
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.

from __future__ import print_function

import argparse
import codecs
import logging
from lxml import etree
from multiprocessing import Pool
import os
import sys
import textwrap

from nltk.sem.logic import LogicalExpressionException

from .ccg2lambda_tools import assign_semantics_to_ccg
from .semantic_index import SemanticIndex


def main(args = None):
    global ARGS
    DESCRIPTION=textwrap.dedent("""\
            categories_template.yaml should contain the semantic templates
              in YAML format.
            parsed_sentence.xml contains the CCG-parsed sentences.
            If --arbi-types is specified, then the arbitrary specification of
              types is enabled, thus using the argument as the field of the semantic
              template that is used. E.g, by specifying "--arbi-types coq_type"
              and a semantic template:
            - semantics: \P x.P(x)
              category: NP
              coq_type: Animal
            The type "Animal" will be used for this expression. Otherwise,
            types of the sem/logic module of NLTK are used.
      """)

    parser = argparse.ArgumentParser(
        formatter_class=argparse.RawDescriptionHelpFormatter,
        description=DESCRIPTION)
    parser.add_argument("ccg")
    parser.add_argument("templates")
    parser.add_argument("sem")
    parser.add_argument("--gold_trees", action="store_true", default=True)
    parser.add_argument("--nbest", nargs='?', type=int, default="0")
    ARGS = parser.parse_args()

    if not os.path.exists(ARGS.templates):
        print('File does not exist: {0}'.format(ARGS.templates))
        sys.exit(1)
    if not os.path.exists(ARGS.ccg):
        print('File does not exist: {0}'.format(ARGS.ccg))
        sys.exit(1)

    logging.basicConfig(level=logging.WARNING)

    semantic_index = SemanticIndex(ARGS.templates)

    parser = etree.XMLParser(remove_blank_text=True)
    root = etree.parse(ARGS.ccg, parser)

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
    with codecs.open(ARGS.sem, 'wb') as fout:
        fout.write(root_xml_str)

def semantic_parse_sentences(sentence_inds,
                             sentences, semantic_index):
    sem_nodes_lists = semantic_parse_sentences_seq(sentence_inds,
                                                   sentences, semantic_index)
    sem_nodes_lists = [
        [etree.fromstring(s) for s in sem_nodes] for sem_nodes in sem_nodes_lists]
    return sem_nodes_lists

def semantic_parse_sentences_seq(sentence_inds, sentences, semantic_index):
    sem_nodes = []
    for sentence_ind in sentence_inds:
        sem_node = semantic_parse_sentence(sentence_ind,
                                           sentences, semantic_index)
        sem_nodes.append(sem_node)
    return sem_nodes

def semantic_parse_sentence(sentence_ind, sentences, semantic_index, nbest=0):
    """
    `sentence` is an lxml tree with tokens and ccg nodes.
    It returns an lxml semantics node.
    """
    sentence = sentences[sentence_ind]
    sem_nodes = []
    # TODO: try to prevent semantic parsing for fragmented CCG trees.
    # Otherwise, produce fragmented semantics.
    # In xpath, elements are 1-indexed.
    # However, gold_tree annotations assumed zero-index.
    # This line fixes it.
    tree_indices = [int(sentence.get('gold_tree', '0')) + 1]

    if nbest != 1:
        tree_indices = get_tree_indices(sentence, nbest)
    for tree_index in tree_indices:
        sem_node = etree.Element('semantics')
        try:
            sem_tree = assign_semantics_to_ccg(
                sentence, semantic_index, tree_index)
            filter_attributes(sem_tree)
            sem_node.extend(sem_tree.xpath('.//descendant-or-self::span'))
            sem_node.set('status', 'success')
            sem_node.set('ccg_id',
                sentence.xpath('./ccg[{0}]/@id'.format(tree_index))[0])
            sem_node.set('root',
                sentence.xpath('./ccg[{0}]/@root'.format(tree_index))[0])
            # print('.', end='', file=sys.stdout)
            sys.stdout.flush()
        except Exception as e:
            sem_node.set('status', 'failed')
            # from pudb import set_trace; set_trace()
            sentence_surf = ' '.join(sentence.xpath('tokens/token/@surf'))
            logging.error('An error occurred: {0}\nSentence: {1}\nTree XML:\n{2}'.format(
                e, sentence_surf,
                etree.tostring(sentence, encoding='utf-8', pretty_print=True).decode('utf-8')))
            # print('x', end='', file=sys.stdout)
            sys.stdout.flush()
        sem_nodes.append(sem_node)
    return [etree.tostring(sem_node) for sem_node in sem_nodes]

def get_tree_indices(sentence, nbest):
    num_ccg_trees = int(sentence.xpath('count(./ccg)'))
    if nbest < 1:
        nbest = num_ccg_trees
    return list(range(1, min(nbest, num_ccg_trees) + 1))

keep_attributes = set(['id', 'child', 'sem', 'type'])
def filter_attributes(tree):
    if 'coq_type' in tree.attrib and 'child' not in tree.attrib:
        sem_type = \
            tree.attrib['coq_type'].lstrip('["Parameter ').rstrip('."]')
        if sem_type:
            tree.attrib['type'] = sem_type
    attrib_to_delete = [a for a in tree.attrib.keys() if a not in keep_attributes]
    for a in attrib_to_delete:
        del tree.attrib[a]
    for child in tree:
        filter_attributes(child)
    return

def serialize_tree(tree):
    tree_str = etree.tostring(
        tree, xml_declaration=True, encoding='utf-8', pretty_print=True)
    return tree_str

if __name__ == '__main__':
    main()
