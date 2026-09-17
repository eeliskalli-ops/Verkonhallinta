                                    Tehtävä 3 Monitorointi
Eelis Källi 17.09.2026

Johdanto

Monitorointi on palvelujen ja prosessien suorituskyvyn, sekä resurssien kulutuksen seurantaa.
Monitoroinnilla voidaan löytää järjestelmän sisäisiä heikkouksia, sekä havaita suorituskyvyn laskua ja resurssien epänormaalia kulutusta. Tämän avulla voidaan löytää heikkoudet ennen kuin niistä aiheutuu käyttökatkoja käyttäjälle. 
Prometheus on järjestelmässä valvova, sekä hälyttävä avoin lähdekoodi järjestelmä. Tämä tarkoittaa, että kuka vain voi käyttää järjestelmää ja sitä voi muokata vapaasti omien tarpeidensa mukaan. Prometheus dataa metriikka muodossa, joka tarkoittaa muutoksien tietyn aikavälin aikana. 

Ympäristön rakentaminen

Ympäristössä oli valmiina asennettuina suurin osa tarvittavista järjestelmistä, joten minun ei tarvinnut asentaa muuta kuin node exporter. Node Exporterin tehtävänä on muuttaa käyttöjärjestelmän raakadata Prometheuksen ymmärtämään aikasarjamuotoon.
NodeExporterin asennukseen tarvittiin työkalut (wget ja tar), jonka jälkeen latasin Node Exporterin GitHubista, purin sen ja käynnistin palvelun komennolla:
	./node_exporter
NodeExporter toimii oletuksena porttiin "http://prometheus:9090" ja Prometheus osaa nuuskia tiedot sieltä.

Mittarien kerääminen

Mitä kohteita valvoin:  
Valvon kolmea palvelinta: client1, web1 ja db1. Nämä ovat Prometheuksen targets‑listassa näkyvät koneet, joilta Node Exporter tuottaa mittarit.

Mitä mittareita keräsin:  
Kerään CPU‑kuorman, muistin käytön, levytilan, verkkoliikenteen (receive ja transmit) sekä muut Node Exporterin tuottamat järjestelmätason mittarit. 

CPU-käyrä meni idle 1.5% suoraan 5.5% ja disk usage muuttui vain 6.255% 6.355% en huomannut eroja verkkoliikenteessä. 

Prometheus kyselyt

Ensimmäinen PromQL Prompti kysyy kuinka kauan CPU viettää idle tilassa 5 minuutin keskiarvolla ja muuntaa sen kuormaksi prosentteina.

	100 - (avg by(instance)
		(rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) 


Memory Usage laskee kuinka suuri osa fyysisestä muistista on käytössä. Se käyttää kokonaismuistia ja käytössä olevaa muistia, jolloin tulos on selkeä prosenttiluku.

	(node_memory_MemTotal_bytes -
 		node_memory_MemAvailable_bytes)
		/
		node_memory_MemTotal_bytes
		* 100

Disk Usage kertoo levyjen täyttöasteen prosentteina. Se kertoo kuinka paljon levytilaa on käytetty suhteessa kokonaismäärään. 

	100 -
	(
	node_filesystem_avail_bytes
	/
	node_filesystem_size_bytes
	* 100
	)

Network Recive näyttää verkon sisään tulevan liikenteen määrän sekunteina. Se käyttää 5 minuutin liukuvaa keskiarvo, jotta tulos olisi tasainen. 

	rate(node_network_receive_bytes_total[5m])

Network Transmit kysely näyttää ulos menevän liikenteen määrän sekunnissa.
	rate(node_network_transmit_bytes_total[5m])

Grafana näkymät

Rakensin 5 erillistä dashboard näkymää mistä jo mainittu aikaisemmin raportissa. Nämä perustuvat Node Exporterin keräämään dataan.

CPU Usage % 
Paneeli näyttää jokaisen palvelimen CPU‑kuorman prosentteina. Tämä auttaa havaitsemaan, jos jokin palvelin kuormittuu liikaa tai jos jokin prosessi vie epätavallisen paljon tehoa.

Memory Usage % 
Muistin käyttöaste kertoo nopeasti, onko palvelin lähellä muistin loppumista. Tämä on kriittinen mittari, koska muistin täyttyminen aiheuttaa välittömiä suorituskykyongelmia.

Disk Usage % 
Levytilan täyttöaste näyttää, kuinka	 paljon levyä on käytetty. Levyjen täyttyminen on yksi yleisimmistä palvelinkatkoksien syistä, joten tämä mittari on erittäin hyödyllinen ylläpidossa.

Network Recieve 
Näyttää sisään tulevan liikenteen määrän sekunnissa. Tämän avulla näkee, onko palvelimelle tulossa epätavallisen paljon dataa, esimerkiksi kuormitustilanteissa tai mahdollisissa hyökkäyksissä.

Network Transmit
Vaikka transmit‑paneeli ei näy kuvassa, valvon myös ulosmenevää liikennettä. Tämä mittari kertoo, lähettääkö palvelin poikkeuksellisen paljon dataa ulospäin, mikä voi viitata virhetilanteeseen tai sovelluksen ylikuormitukseen.

Havaintoja monitoroinnista

Monitorointi tuotti tietoa CPUn, muistin, levyn käyttöasteen, sekä verkon sisään- ja ulosmenevän liikenteen määrän
CPU-kuormitustesti näkyi välittömästi web1 palvelimen CPU-paneelissa. Käyrä nousi selvästi, mikä todisti Prometheuksen keräävän tiedon oikein. Levytilan käyttö nousi, kun loin tekstitiedoston. Disk Usage paneelissa tämä näkyi pienenä piikkinä. Mittauksien perustella voisi olettaa monitoroinnin toimivan tarkoitetulla tavalla ja reagoivan muutoksiin reaaliajassa.

Pohdinta

Tehtävän aikana opin miten Prometheus ja Grafana toimivat yhdessä  monitorointiympäristössä. Opin myös, miten Node Exporter tuottaa järjestelmätason mittareita ja miten PromQL‑kyselyillä voidaan laskea CPU‑kuorma, muistin käyttö, levytilan täyttöaste ja verkkoliikenne.
Prometheuksen vahvuudet ovat yksinkertainen käyttöönotto ja laaja mittarivalikoima. Node Exporter tuottaa paljon hyödyllistä dataa ilman monimutkaisia asetuksia. Prometheus myös integroituu suoraan Grafanaan, mikä teki visualisoinnista helppoa. Prometheus sopii hyvin palvelinympäristöihin, konttialustoihin ja pilvipalveluihin, joissa tarvitaan reaaliaikasta monitorointia. Prometheus on tarkoitettu lyhytaikaiseen valvontaan ja vaatii usein ulkoisen järjestelmän pitkäaikaisen datan tallennukseen. PromQl vaatii myös oman opettelunsa, koska yksikin väärin kirjoitettu lause voi antaa virheellistä dataa tai jopa estää koko datan keräämisen. 
