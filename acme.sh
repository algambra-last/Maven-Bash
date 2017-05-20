#!/bin/bash

# This script creates new release, tests it and moves it to a remote repository.
if [ "$#" -ne 1 ]
    then
        echo "-------------------------------------------------------------"
        echo "Parameter list is empty - please define release number as x.x"
        echo "-------------------------------------------------------------"
        exit 1
fi

release=$1
branch=Release/$release

# Clean workspace  
cd
[[ -d sbdemo ]] && rm -rf sbdemo
#
#
# Now we have two options:
# 1) Branch Release/xxx already exists.
# In this case, we need to find the last tag, increase build number,
# create the tag and push the current commit to the remote repo.
#
git clone https://github.com/ospector/sbdemo.git
cd ~/sbdemo
branch_exists=`git branch -a | grep $branch | wc -l`
if [ branch_exists == 1 ]
    then
        echo "Branch already exists"
        git checkout $branch
        last_tag=`git describe --abbrev=0 --tags`
        if [ -z "$last_tag" ]
            then
                new_tag=v$release.0        # First tag in branch
                build=$release.0
            else
                IFS='.' read a b c <<< "$last_tag"
                c=$((c+1))
                new_tag=$a.$b.$c
                build=${new_tag#?}
        fi
        sed -i "s#<version>$release-SNAPSHOT</version>#<version>$build</version>#" pom.xml
        mvn install -DskipTests
#
        if [ $? ]
            then
                echo "Build succeeded"
                sed -i "s#<version>$build</version>#<version>$release-SNAPSHOT</version>#" pom.xml
                git add *
                git commit -m "Build $build"
                git tag $new_tag
# Uncomment the following line when you're runing the script with the sufficient permissions to write into the repo
#                git push origin --tags $branch:$branch
            else
                echo "Build failed"
        fi


#
# 2) Branch Release/xxx doesn't exist.
# In this case, we need to create a new tag with the build number=0 and
# to push the branch to the remote repo.
#
    else
        echo "Create new branch"
        git checkout -b $branch
        build=$release.0
        sed -i "s#<version>development-SNAPSHOT</version>#<version>$build</version>#" pom.xml
        mvn install -DskipTests
#
        if [ $? ] 
            then
                echo "Build succeeded"
                sed -i "s#<version>$build</version>#<version>$release-SNAPSHOT</version>#" pom.xml
                new_tag=v$release.0
                git add *
                git commit -m "Build $build"
                git tag $new_tag
# Uncomment the following line when you're runing the script with the sufficient permissions to write into the repo
#                git push origin --tags $branch:$branch
            else
                echo "Build failed"
        fi
fi
