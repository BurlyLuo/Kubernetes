pip install kubernetes[For Python Client]
[root@k8s-1 python]# yum install python-pip
[root@k8s-1 python]# pip

Usage:   
  pip <command> [options]

Commands:
  install                     Install packages.
  download                    Download packages.
  uninstall                   Uninstall packages.
  freeze                      Output installed packages in requirements format.
  list                        List installed packages.
  show                        Show information about installed packages.
  search                      Search PyPI for packages.
  wheel                       Build wheels from your requirements.
  hash                        Compute hashes of package archives.
  completion                  A helper command used for command completion
  help                        Show help for commands.

General Options:
  -h, --help                  Show help.
  --isolated                  Run pip in an isolated mode, ignoring environment variables and user configuration.
  -v, --verbose               Give more output. Option is additive, and can be used up to 3 times.
  -V, --version               Show version and exit.
  -q, --quiet                 Give less output.
  --log <path>                Path to a verbose appending log.
  --proxy <proxy>             Specify a proxy in the form [user:passwd@]proxy.server:port.
  --retries <retries>         Maximum number of retries each connection should attempt (default 5 times).
  --timeout <sec>             Set the socket timeout (default 15 seconds).
  --exists-action <action>    Default action when a path already exists: (s)witch, (i)gnore, (w)ipe, (b)ackup.
  --trusted-host <hostname>   Mark this host as trusted, even though it does not have valid or any HTTPS.
  --cert <path>               Path to alternate CA bundle.
  --client-cert <path>        Path to SSL client certificate, a single file containing the private key and the certificate in PEM format.
  --cache-dir <dir>           Store the cache data in <dir>.
  --no-cache-dir              Disable the cache.
  --disable-pip-version-check
                              Don't periodically check PyPI to determine whether a new version of pip is available for download. Implied with --no-index.
[root@k8s-1 python]# pip install kubernetes
Collecting kubernetes
  Downloading https://files.pythonhosted.org/packages/40/eb/4d6a80db84ac24c867c94fbf16e6f26db9780f5232f46ddd2e5539b42205/kubernetes-8.0.1-py2.py3-none-any.whl (1.3MB)
    100% |████████████████████████████████| 1.4MB 344kB/s
Collecting ipaddress>=1.0.17; python_version == "2.7" (from kubernetes)
  Downloading https://files.pythonhosted.org/packages/fc/d0/7fc3a811e011d4b388be48a0e381db8d990042df54aa4ef4599a31d39853/ipaddress-1.0.22-py2.py3-none-any.whl
Collecting websocket-client!=0.40.0,!=0.41.*,!=0.42.*,>=0.32.0 (from kubernetes)
  Downloading https://files.pythonhosted.org/packages/38/54/684db2ba1b7a203602808446b8686ee786f93b4a7e080cdc440cc7e06e56/websocket_client-0.55.0-py2.py3-none-any.whl (200kB)
    100% |████████████████████████████████| 204kB 432kB/s
Collecting setuptools>=21.0.0 (from kubernetes)
  Downloading https://files.pythonhosted.org/packages/d1/6a/4b2fcefd2ea0868810e92d519dacac1ddc64a2e53ba9e3422c3b62b378a6/setuptools-40.8.0-py2.py3-none-any.whl (575kB)
    100% |████████████████████████████████| 583kB 478kB/s
Collecting certifi>=14.05.14 (from kubernetes)
  Downloading https://files.pythonhosted.org/packages/60/75/f692a584e85b7eaba0e03827b3d51f45f571c2e793dd731e598828d380aa/certifi-2019.3.9-py2.py3-none-any.whl (158kB)
    100% |████████████████████████████████| 163kB 596kB/s
Collecting pyyaml>=3.12 (from kubernetes)
  Downloading https://files.pythonhosted.org/packages/9f/2c/9417b5c774792634834e730932745bc09a7d36754ca00acf1ccd1ac2594d/PyYAML-5.1.tar.gz (274kB)
    100% |████████████████████████████████| 276kB 497kB/s
Collecting requests-oauthlib (from kubernetes)
  Downloading https://files.pythonhosted.org/packages/c2/e2/9fd03d55ffb70fe51f587f20bcf407a6927eb121de86928b34d162f0b1ac/requests_oauthlib-1.2.0-py2.py3-none-any.whl
Collecting six>=1.9.0 (from kubernetes)
  Downloading https://files.pythonhosted.org/packages/73/fb/00a976f728d0d1fecfe898238ce23f502a721c0ac0ecfedb80e0d88c64e9/six-1.12.0-py2.py3-none-any.whl
Collecting adal>=1.0.2 (from kubernetes)
  Downloading https://files.pythonhosted.org/packages/00/72/53dce9e4f5d6c1aa57b8d408cb34dff1969ecbf10ab7e678f32c5e0e2397/adal-1.2.1-py2.py3-none-any.whl (52kB)
    100% |████████████████████████████████| 61kB 337kB/s
Collecting requests (from kubernetes)
  Downloading https://files.pythonhosted.org/packages/7d/e3/20f3d364d6c8e5d2353c72a67778eb189176f08e873c9900e10c0287b84b/requests-2.21.0-py2.py3-none-any.whl (57kB)
    100% |████████████████████████████████| 61kB 1.7MB/s
Collecting python-dateutil>=2.5.3 (from kubernetes)
  Downloading https://files.pythonhosted.org/packages/41/17/c62faccbfbd163c7f57f3844689e3a78bae1f403648a6afb1d0866d87fbb/python_dateutil-2.8.0-py2.py3-none-any.whl (226kB)
    100% |████████████████████████████████| 235kB 572kB/s
Collecting google-auth>=1.0.1 (from kubernetes)
  Downloading https://files.pythonhosted.org/packages/c5/9b/ed0516cc1f7609fb0217e3057ff4f0f9f3e3ce79a369c6af4a6c5ca25664/google_auth-1.6.3-py2.py3-none-any.whl (73kB)
    100% |████████████████████████████████| 81kB 595kB/s
Collecting urllib3>=1.23 (from kubernetes)
  Downloading https://files.pythonhosted.org/packages/62/00/ee1d7de624db8ba7090d1226aebefab96a2c71cd5cfa7629d6ad3f61b79e/urllib3-1.24.1-py2.py3-none-any.whl (118kB)
    100% |████████████████████████████████| 122kB 628kB/s
Collecting oauthlib>=3.0.0 (from requests-oauthlib->kubernetes)
  Downloading https://files.pythonhosted.org/packages/16/95/699466b05b72b94a41f662dc9edf87fda4289e3602ecd42d27fcaddf7b56/oauthlib-3.0.1-py2.py3-none-any.whl (142kB)
    100% |████████████████████████████████| 143kB 446kB/s
Collecting cryptography>=1.1.0 (from adal>=1.0.2->kubernetes)
  Downloading https://files.pythonhosted.org/packages/c3/c1/cf8665c955c9393e9ff0872ba6cd3dc6f46ef915e94afcf6e0410508ca69/cryptography-2.6.1-cp27-cp27mu-manylinux1_x86_64.whl (2.3MB)
    100% |████████████████████████████████| 2.3MB 302kB/s
Collecting PyJWT>=1.0.0 (from adal>=1.0.2->kubernetes)
  Downloading https://files.pythonhosted.org/packages/87/8b/6a9f14b5f781697e51259d81657e6048fd31a113229cf346880bb7545565/PyJWT-1.7.1-py2.py3-none-any.whl
Collecting chardet<3.1.0,>=3.0.2 (from requests->kubernetes)
  Downloading https://files.pythonhosted.org/packages/bc/a9/01ffebfb562e4274b6487b4bb1ddec7ca55ec7510b22e4c51f14098443b8/chardet-3.0.4-py2.py3-none-any.whl (133kB)
    100% |████████████████████████████████| 143kB 444kB/s
Collecting idna<2.9,>=2.5 (from requests->kubernetes)
  Downloading https://files.pythonhosted.org/packages/14/2c/cd551d81dbe15200be1cf41cd03869a46fe7226e7450af7a6545bfc474c9/idna-2.8-py2.py3-none-any.whl (58kB)
    100% |████████████████████████████████| 61kB 1.7MB/s
Collecting pyasn1-modules>=0.2.1 (from google-auth>=1.0.1->kubernetes)
  Downloading https://files.pythonhosted.org/packages/da/98/8ddd9fa4d84065926832bcf2255a2b69f1d03330aa4d1c49cc7317ac888e/pyasn1_modules-0.2.4-py2.py3-none-any.whl (66kB)
    100% |████████████████████████████████| 71kB 573kB/s
Collecting cachetools>=2.0.0 (from google-auth>=1.0.1->kubernetes)
  Downloading https://files.pythonhosted.org/packages/39/2b/d87fc2369242bd743883232c463f28205902b8579cb68dcf5b11eee1652f/cachetools-3.1.0-py2.py3-none-any.whl
Collecting rsa>=3.1.4 (from google-auth>=1.0.1->kubernetes)
  Downloading https://files.pythonhosted.org/packages/02/e5/38518af393f7c214357079ce67a317307936896e961e35450b70fad2a9cf/rsa-4.0-py2.py3-none-any.whl
Collecting enum34; python_version < "3" (from cryptography>=1.1.0->adal>=1.0.2->kubernetes)
  Downloading https://files.pythonhosted.org/packages/c5/db/e56e6b4bbac7c4a06de1c50de6fe1ef3810018ae11732a50f15f62c7d050/enum34-1.1.6-py2-none-any.whl
Collecting asn1crypto>=0.21.0 (from cryptography>=1.1.0->adal>=1.0.2->kubernetes)
  Downloading https://files.pythonhosted.org/packages/ea/cd/35485615f45f30a510576f1a56d1e0a7ad7bd8ab5ed7cdc600ef7cd06222/asn1crypto-0.24.0-py2.py3-none-any.whl (101kB)
    100% |████████████████████████████████| 102kB 563kB/s
Collecting cffi!=1.11.3,>=1.8 (from cryptography>=1.1.0->adal>=1.0.2->kubernetes)
  Downloading https://files.pythonhosted.org/packages/9d/6f/aea9f5559fb593da07ff34e67513bd62483b45715b4a5f5fae6a0a5792ea/cffi-1.12.2-cp27-cp27mu-manylinux1_x86_64.whl (413kB)
    100% |████████████████████████████████| 419kB 407kB/s
Collecting pyasn1<0.5.0,>=0.4.1 (from pyasn1-modules>=0.2.1->google-auth>=1.0.1->kubernetes)
  Downloading https://files.pythonhosted.org/packages/7b/7c/c9386b82a25115cccf1903441bba3cbadcfae7b678a20167347fa8ded34c/pyasn1-0.4.5-py2.py3-none-any.whl (73kB)
    100% |████████████████████████████████| 81kB 629kB/s
Collecting pycparser (from cffi!=1.11.3,>=1.8->cryptography>=1.1.0->adal>=1.0.2->kubernetes)
  Downloading https://files.pythonhosted.org/packages/68/9e/49196946aee219aead1290e00d1e7fdeab8567783e83e1b9ab5585e6206a/pycparser-2.19.tar.gz (158kB)
    100% |████████████████████████████████| 163kB 535kB/s
Installing collected packages: ipaddress, six, websocket-client, setuptools, certifi, pyyaml, oauthlib, urllib3, chardet, idna, requests, requests-oauthlib, enum34, asn1crypto, pycparser, cffi, cryptography, PyJWT, python-dateutil, adal, pyasn1, pyasn1-modules, cachetools, rsa, google-auth, kubernetes
  Found existing installation: ipaddress 1.0.16
    DEPRECATION: Uninstalling a distutils installed project (ipaddress) has been deprecated and will be removed in a future version. This is due to the fact that uninstalling a distutils project will only partially uninstall the project.
    Uninstalling ipaddress-1.0.16:
      Successfully uninstalled ipaddress-1.0.16
  Found existing installation: setuptools 0.9.8
    Uninstalling setuptools-0.9.8:
      Successfully uninstalled setuptools-0.9.8
  Running setup.py install for pyyaml ... done
  Found existing installation: chardet 2.2.1
    Uninstalling chardet-2.2.1:
      Successfully uninstalled chardet-2.2.1
  Running setup.py install for pycparser ... done
Successfully installed PyJWT-1.7.1 adal-1.2.1 asn1crypto-0.24.0 cachetools-3.1.0 certifi-2019.3.9 cffi-1.12.2 chardet-3.0.4 cryptography-2.6.1 enum34-1.1.6 google-auth-1.6.3 idna-2.8 ipaddress-1.0.22 kubernetes-8.0.1 oauthlib-3.0.1 pyasn1-0.4.5 pyasn1-modules-0.2.4 pycparser-2.19 python-dateutil-2.8.0 pyyaml-5.1 requests-2.21.0 requests-oauthlib-1.2.0 rsa-4.0 setuptools-40.8.0 six-1.12.0 urllib3-1.24.1 websocket-client-0.55.0
You are using pip version 8.1.2, however version 19.0.3 is available.
You should consider upgrading via the 'pip install --upgrade pip' command.
[root@k8s-1 python]#
