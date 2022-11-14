import 'dart:io';
import 'dart:math' as Math;

List applyHammingWindow(List frame)
{
  File file = File("hmm/Hamming_window.txt");
  var fileContent = file.readAsStringSync();

  List hammingCoefficients = fileContent.split(' ');

  for(int i=0; i<320; i++)
  {
    frame[i]=frame[i]*hammingCoefficients[i];
  }

  return frame;
}

List applyRaisedSineWindow(List frame)
{
    for(int i=0; i<12; i++)
    {
        double aux=Math.sin((Math.pi*(i+1))/12.0);
        frame[i] = frame[i]*(1.0+6.0*aux);
    }

    return frame;
}

double compute_correlation(List frame, int lag)
{
  double correlation=0.0;
  for(int index=lag; index<frame.length; index++)
    {
        correlation+=frame[index]*frame[index-lag];
    }
    return correlation;
}

List compute_levensionDurbins(List correlation_coefficients)
{
  double e=correlation_coefficients[0];
  double k;
  List aux = new List();
  List lpc_coefficients = new List();

  for(int i=1; i<=12; i++)
  {

    k=correlation_coefficients[i];
    for(int j=1; j<i; j++)
    {
        k-= lpc_coefficients[j-1]*correlation_coefficients[i-j];
    }
    k/=e;
    
    for(int j=1; j<i; j++)
    {
        aux[j-1]=lpc_coefficients[j-1]-k*lpc_coefficients[i-j-1];
    }    
    aux.add(k);

    lpc_coefficients = aux;
    e = (1-k*k)*e;

  }

  return lpc_coefficients;
}

List compute_cepstral_coefficients(List lpc_coefficients)
{
  List cepstral_coefficients = new List();

  for(int i=0;i<12;i++)
  {
      cepstral_coefficients.add(lpc_coefficients[i]);
      for(int j=0; j<i; j++)
      {
          cepstral_coefficients[i] += ((j+1)/(i+1)) * cepstral_coefficients[j] * lpc_coefficients[i-j-1];
      }
  }

  return cepstral_coefficients;
}

List get_observation_sequence(List amplitudes)
{
  var seq = new List(); 

  for(int i=0; i+320<amplitudes.length; i+=320)
  {
    List frame = new List();
    for(int j=i; j<i+320; j++)
    {
      frame.add(amplitudes[j]);
    }

    frame = applyHammingWindow(frame);

    List correlation_coefficients = new List();
    for(int k=0;k<=12;k++)
    {
        correlation_coefficients.add(compute_correlation(frame, k));
    }

    List lpc_coefficients = new List();
    lpc_coefficients = compute_levensionDurbins(correlation_coefficients);
  
    List cepstral_coefficients = new List();
    cepstral_coefficients = compute_cepstral_coefficients(lpc_coefficients);

    cepstral_coefficients = applyRaisedSineWindow(cepstral_coefficients);

    File file = File("hmm/codebook.csv");
    var fileContent = file.readAsStringSync();

    List codeBook = fileContent.split(',');

    int obs=-1;
    double mndis=0;
    for(int k=0; k<32; k++)
    {
      double dis=0;
      for(int j=0; j<12; j++)
      {
        int ind=j+k*12;
        dis += (codeBook[ind]-cepstral_coefficients[j])*(codeBook[ind]-cepstral_coefficients[j]);
      }

      if(obs==-1 || mndis>dis)
      {
        obs=k;
        mndis=dis;
      }
    }

    seq.add(obs);
  }

  return seq;
}

double forward_procedure(List pi, List a, List b, int n, int m, List o, int T)
{
  List alpha = new List.generate(T, (_) => new List(n));

	for(int j=0; j<n; j++)
	{
		alpha[0][j]=pi[j]*b[0][o[0]-1];
	}
	
	for(int i=1; i<T; i++)
	{
		for(int j=0; j<n; j++)
		{
			alpha[i][j]=0.0;
			for(int k=0; k<n; k++)
			{
				alpha[i][j]+=alpha[i-1][k]*a[k][j];
			}
			alpha[i][j]*=b[j][o[i]-1];
		}
	}

	double prob=0.0;
	for(int i=0; i<n; i++)
	{
		prob+=alpha[T-1][i];
	}
	
	//print alpha
	//for(int i=0; i<T; i++)
	//{
	//	for(int j=0; j<n; j++)
	//	{
	//		cout<<alpha[i][j]<<" ";
	//	}
	//	cout<<endl;
	//}
	return prob;
}

String _test_hmm(String filePath)
{
  File file = File(filePath);
  var fileContent = file.readAsStringSync();
  
  List amplitudes = fileContent.split('\n');

  List observation_sequence = get_observation_sequence(amplitudes);
  int T = observation_sequence.length;

  List words = [
    'hello',
    'hi',
    'hey',
    'thank you',
    'thanks',
    'cost',
    'price',
    'water',
    'drink',
    'food',
    'eat',
    'tourist place',
    'visit place',
    'direction',
    'way',
    'ride'
  ];

  double mxprob=0.0;
  int ans=0;

  for(int i=0; i<words.length; i++)
  {
    File piFile = File("hmm/models/avg_pi_"+words[i]+".txt");
    var piFileContent = piFile.readAsStringSync();
    List pi = piFileContent.split(' ');

    File aFile = File("hmm/models/avg_a_"+words[i]+".txt");
    var aFileContent = aFile.readAsLinesSync();
    List a = new List();
    for(int j=0; j<aFileContent.length; j++)
    {
      a.add(aFileContent[j].split(' '));
    }
    int n=a.length;

    File bFile = File("hmm/models/avg_b_"+words[i]+".txt");
    var bFileContent = bFile.readAsLinesSync();
    List b = new List();
    for(int j=0; j<aFileContent.length; j++)
    {
      b.add(bFileContent[j].split(' '));
    }
    int m=b[0].length;

    double prob=forward_procedure(pi, a, b, n, m, observation_sequence, T);

    if(prob>mxprob)
    {
      mxprob=prob;
      ans=i;
    }

  }

  return words[ans];
}