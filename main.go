package main

import (
	"flag"
	"fmt"
	"log"
	"path/filepath"

	appsv1 "k8s.io/api/apps/v1"
	apiv1 "k8s.io/api/core/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/runtime"
	"k8s.io/apimachinery/pkg/runtime/schema"
	"k8s.io/apimachinery/pkg/types"
	"k8s.io/client-go/kubernetes"
	"k8s.io/client-go/kubernetes/scheme"
	"k8s.io/client-go/tools/clientcmd"
	"k8s.io/client-go/util/homedir"

	_ "k8s.io/client-go/plugin/pkg/client/auth"
)

var (
	kubeconfig = filepath.Join(homedir.HomeDir(), ".kube", "config")
)

func main() {
	flag.StringVar(&kubeconfig, "kubeconfig", kubeconfig, "absolute path to the kubeconfig file")
	flag.Parse()

	config, err := clientcmd.BuildConfigFromFlags("", kubeconfig)
	if err != nil {
		log.Fatal(err)
	}

	clientset, err := kubernetes.NewForConfig(config)
	if err != nil {
		log.Fatal(err)
	}

	deployment := &appsv1.Deployment{
		ObjectMeta: metav1.ObjectMeta{
			Name: "nginx",
		},
		Spec: appsv1.DeploymentSpec{
			Selector: &metav1.LabelSelector{
				MatchLabels: map[string]string{
					"app": "nginx",
				},
			},
			Template: apiv1.PodTemplateSpec{
				ObjectMeta: metav1.ObjectMeta{
					Labels: map[string]string{
						"app": "nginx",
					},
				},
				Spec: apiv1.PodSpec{
					Containers: []apiv1.Container{
						{
							Name:  "nginx",
							Image: "nginx",
						},
					},
				},
			},
		},
	}
	_ = deployment

	sa := &apiv1.ServiceAccount{
		ObjectMeta: metav1.ObjectMeta{
			Name:        "cke-cluster-dns",
			// Namespace:   "kube-system",
			// Annotations: map[string]string{"cke.cybozu.com/revision": "1"},
		},
	}

	// data, err := runtime.Encode(scheme.Codecs.LegacyCodec(appsv1.SchemeGroupVersion), deployment)
	data, err := runtime.Encode(scheme.Codecs.LegacyCodec(schema.GroupVersion{Group: "", Version: "v1"}), sa)
	// data, err := json.Marshal(deployment)
	// if err != nil {
	// 	log.Fatal(err)
	// }
	// data := []byte("{\"kind\":\"ServiceAccount\",\"apiVersion\":\"v1\",\"metadata\":{\"name\":\"cke-cluster-dns\",\"namespace\":\"kube-system\",\"creationTimestamp\":null,\"annotations\":{\"cke.cybozu.com/revision\":\"1\"}}}\n")
	fmt.Println(string(data))
	// data := []byte("")

	req := clientset.CoreV1().RESTClient().Patch(types.ApplyPatchType).
        Namespace("kube-system").
		Resource("serviceaccount").
		Name("cke-cluster-dns").
		Param("fieldManager", "try-server-side-apply").
		Body(data)
	fmt.Printf("%#v", req)
	_, err = req.Do().Get()
	if err != nil {
		log.Fatal(err)
	}
}
