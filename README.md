# GithubReleases

Creating class object:
</br>
![image](https://github.com/TheBrunoCA/GithubReleases/assets/69942183/d8eb80c0-06ea-45fd-b0df-070f4d4e11b3)

Getting the releases info from Github's Api, remember that doing this will consume your hourly api limit:
</br>
![image](https://github.com/TheBrunoCA/GithubReleases/assets/69942183/f2bb45bd-fbcd-4a1b-9438-f9c149866fd1)

Reading the releases Json and converting it into a Array of Maps with coco's JXON.ahk, this is not necessary,
 the methods will do this themselves:
</br>
![image](https://github.com/TheBrunoCA/GithubReleases/assets/69942183/f110c8d0-b2d3-449b-b769-a344037d7620)

Getting an Array of releases, each is a Map containing various release's info.
</br>
![image](https://github.com/TheBrunoCA/GithubReleases/assets/69942183/b941ea06-acc8-40ce-ae96-c04c540ed7ac)

Getting only the latest release:
</br>
![image](https://github.com/TheBrunoCA/GithubReleases/assets/69942183/10437b44-f17a-4e8d-94da-76f885bda7fc)

Getting the download link to the latest release:
</br>
![image](https://github.com/TheBrunoCA/GithubReleases/assets/69942183/66323b77-a61d-48df-93d1-7ed2b54ebe8b)

Getting the latest release version, or tag_name:
![image](https://github.com/TheBrunoCA/GithubReleases/assets/69942183/034d7b72-10f6-4964-bc2d-d5990f05582a)

Getting if the current version is up to date with the latest release:
![image](https://github.com/TheBrunoCA/GithubReleases/assets/69942183/26a5d177-9659-489b-bdd8-369bafd3b0c0)
