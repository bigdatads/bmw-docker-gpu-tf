import jaydebeapi
import urllib
import yaml

class HiveFactory(object):
    def __init__(self, user, password):
        '''
        :param user: e.g. user
        :param password: password
        '''

        print('Reading config.yml...')
        with open('config.yml', 'r') as ymlfile:
            cfg = yaml.load(ymlfile)
        cfg_hive = cfg['hive']

        print('Initializing variables...')
        self._keystore_url = cfg['keystore']
        self._base_url = cfg_hive['baseurl']
        self._prodexpl = cfg_hive['prodexpl']
        self._intexpl = cfg_hive['intexpl']
        self._jdbc_driver_class_name = cfg['classname']
        self._jdbc_driver_jar = cfg['jar']

        self._username = user
        self._password = password
        self.engine = None

        print('Download keystore...')
        downloader = urllib.URLopener()
        downloader.retrieve(self._keystore_url, 'store.jks')

    def create_engine(self, endpoint='prodexpl'):
        '''
        :param prodexpl: either one of 'prodexpl' or 'intexpl'
        :returns: the HiveFactory object
        '''
        host = ''
        if endpoint == 'prodexpl':
            host = self._base_url.format(self._prodexpl)
        elif endpoint == 'intexpl':
            host = self._base_url.format(self._intexpl)
        else:
            raise NotImplementedError()

        self.engine = jaydebeapi.connect(
            jclassname=self._jdbc_driver_class_name,
            url=host,
            driver_args=[self._username, self._password],
            jars=self._jdbc_driver_jar
        )

        return self