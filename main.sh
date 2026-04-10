# create ~/bin and add it to PATH for this session
mkdir -p ~/bin
export PATH=~/bin:$PATH

# download Repo
curl https://storage.googleapis.com/git-repo-downloads/repo > ~/bin/repo

# make Repo executable
chmod a+x ~/bin/repo

# add to path
echo 'export PATH=~/bin:$PATH' >> ~/.bashrc

# refresh
source ~/.bashrc

# clone los quickly
mkdir los && cd los
repo init -u https://github.com/LineageOS/android.git -b lineage-23.2 --git-lfs
repo sync --force-sync --force-checkout --retry-fetches=128 --no-tags --no-clone-bundle -j64

