
# wrapper functions of ccg2lambda/scripts/
from subprocess import run
from pathlib import Path


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
    cp = run(["python", "scripts/semparse.py",
              txtfilename+".xml",
              "ja/semantic_templates_ja_emnlp2016.yaml",
              txtfilename+".sem.xml", "--arbi-types"],
             capture_output=True)
    stdout = cp.stdout.decode()
    stderr = cp.stderr.decode()
    # print("stdout:", stdout)
    # print("stderr first 50 characters: ", [:50])
    if not Path(txtfilename+".sem.xml").exists():
        raise Exception("output file doesn't exist,"
                        "so scripts/semparse.py seems to have failed.")
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
              txtfilename+".sem.xml"],
             capture_output=True)
    stdout = cp.stdout.decode()
    stderr = cp.stderr.decode()
    # print("stdout:", stdout)
    # print("stderr first 50 characters: ", [:50])
    assert stdout in ["yes", "no", "unknown"]
    return


if __name__ == '__main__':
    filename = 'tmp.txt'
    _jiggparse(filename)
    _semparse(filename)
    _visualize(filename)
